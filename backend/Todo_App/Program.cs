using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Driver;

var builder = WebApplication.CreateBuilder(args);

// ---- CORS: allow your React dev server ----
builder.Services.AddCors(o =>
{
    o.AddPolicy("AllowReactApp", p =>
        p.AllowAnyOrigin()  // Allow all origins for now (can restrict later)
         .AllowAnyHeader()
         .AllowAnyMethod());
});

// ---- JSON camelCase (matches your FE) ----
builder.Services.ConfigureHttpJsonOptions(o =>
{
    o.SerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
});

// ---- Mongo connection (safe against double port) ----
var mongoHost = Environment.GetEnvironmentVariable("MONGODB_HOST") ?? "mongodb";
var mongoPort = Environment.GetEnvironmentVariable("MONGODB_PORT") ?? "27017";
var mongoDb = Environment.GetEnvironmentVariable("MONGODB_DATABASE") ?? "ToDoDb";

// if host already includes a port, don't append it again
var hostPort = mongoHost.Contains(':') ? mongoHost : $"{mongoHost}:{mongoPort}";
var connStr = $"mongodb://{hostPort}/?directConnection=true";

builder.Services.AddSingleton<IMongoClient>(new MongoClient(connStr));
builder.Services.AddScoped(sp => sp.GetRequiredService<IMongoClient>().GetDatabase(mongoDb));

var app = builder.Build();

app.UseRouting();
app.UseCors("AllowReactApp");

app.UseDefaultFiles();
app.UseStaticFiles();

// ---- Diagnostics ----
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

// optional ping to confirm DB connectivity during debugging
app.MapGet("/diag/ping", async (IMongoDatabase db) =>
{
    try
    {
        var result = await db.RunCommandAsync<BsonDocument>(new BsonDocument("ping", 1));
        return Results.Ok(new { ok = result.GetValue("ok", 0).ToDouble() });
    }
    catch (Exception ex)
    {
        return Results.Problem(ex.Message);
    }
});

// ---- CRUD ----

// GET all
app.MapGet("/api/tasks", async (IMongoDatabase db) =>
{
    try
    {
        var list = await db.GetCollection<TodoItem>("tasks")
                           .Find(_ => true).ToListAsync();
        return Results.Ok(list);
    }
    catch (Exception ex)
    {
        return Results.Problem(ex.Message);
    }
});

// GET one by Guid
app.MapGet("/api/tasks/{id}", async (Guid id, IMongoDatabase db) =>
{
    var col = db.GetCollection<TodoItem>("tasks");
    var item = await col.Find(t => t.Id == id).FirstOrDefaultAsync();
    return item is not null ? Results.Ok(item) : Results.NotFound();
});

// POST create
app.MapPost("/api/tasks", async (TodoItem todo, IMongoDatabase db) =>
{
    try
    {
        // ensure new Guid if not supplied
        if (todo.Id == Guid.Empty) todo.Id = Guid.NewGuid();

        await db.GetCollection<TodoItem>("tasks").InsertOneAsync(todo);
        return Results.Created($"/api/tasks/{todo.Id}", todo);
    }
    catch (Exception ex)
    {
        return Results.Problem(ex.Message);
    }
});

// PUT update
app.MapPut("/api/tasks/{id}", async (Guid id, TodoItem updated, IMongoDatabase db) =>
{
    var col = db.GetCollection<TodoItem>("tasks");
    var existing = await col.Find(t => t.Id == id).FirstOrDefaultAsync();
    if (existing is null) return Results.NotFound();

    // keep the same Guid
    updated.Id = id;

    var res = await col.ReplaceOneAsync(t => t.Id == id, updated);
    return res.ModifiedCount > 0 ? Results.Ok(updated) : Results.NotFound();
});

// DELETE
app.MapDelete("/api/tasks/{id}", async (Guid id, IMongoDatabase db) =>
{
    var res = await db.GetCollection<TodoItem>("tasks")
                      .DeleteOneAsync(t => t.Id == id);
    return res.DeletedCount > 0 ? Results.Ok() : Results.NotFound();
});

//Fall back  client-side routes like /about or /todos/123
app.MapFallbackToFile("index.html");

app.Run();

// ---- Model: single ID (Guid) used as Mongo _id ----
public class TodoItem
{
    // Make your Guid the document key in Mongo
    [BsonId]
    [BsonRepresentation(BsonType.String)]
    public Guid Id { get; set; }

    public string Name { get; set; } = string.Empty;
    public bool IsComplete { get; set; }
}
