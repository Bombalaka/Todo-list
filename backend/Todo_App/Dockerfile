# ---------- Stage 1: Build FRONTEND using node.js ----------
FROM node:18 AS frontend-builder
WORKDIR /frontend

# copy frontend source (path from build context root)
COPY Todo_App/ ./
# install & build (ci first if lockfile exists)
RUN npm ci || npm install
RUN npm run build

# ---------- Stage 2: Build BACKEND ----------
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
# copy backend source
COPY backend/Todo_App/ ./
RUN dotnet restore
RUN dotnet publish -c Release -o /app/publish

# ---------- Stage 3: Runtime (serve FE + API) ----------
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

# put built React files into wwwroot so ASP.NET serves them
COPY --from=frontend-builder /frontend/dist ./wwwroot
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Todo_App.dll"]
