import React, { useState, useEffect } from "react"
import axios from "axios";

const API_URL = import.meta.env.VITE_API_URL || "";

function ToDoList() {
    // store tasks as objects so we have stable ids for keys and easier updates
    const [tasks, setTasks] = useState([]);
    const [newTask, setNewTask] = useState("");
    const [editingId, setEditingId] = useState(null);
    const [editingText, setEditingText] = useState("");

    //Fetch tasks when component mounts
    useEffect(() => {
        fetchTasks();
    }, []);

    //fecth tasks from backend
    async function fetchTasks() {
        try {
            const response = await axios.get(`${API_URL}/api/tasks`);
            const mappedTasks = response.data.map(task => ({
                id: task.id,
                text: task.name,
                completed: task.isComplete || false
            }));
            setTasks(mappedTasks);
        } catch (error) {
            console.error("Error fetching tasks:", error);
        }
    }


// use for retive data from local storage
function handleInputChange(event) {
    setNewTask(event.target.value);
}

async function addTask() {
    if (newTask.trim() !== "") {
        try {
                const response = await axios.post(`${API_URL}/api/tasks`, {
                    Name: newTask.trim()
                });
                
                const taskObj = {
                    id: response.data.id,
                    text: response.data.name,
                    completed: response.data.isComplete || false
                };
                
                setTasks(prev => [...prev, taskObj]);
                setNewTask("");
            } catch (error) {
                console.error("Error adding task:", error);
            }
        }
    }


async function deleteTask(id) {
    try {
        await axios.delete(`${API_URL}/api/tasks/${id}`);
        setTasks(prev => prev.filter(t => t.id !== id));
    } catch (error) {
        console.error("Error deleting task:", error);
    }
}

function startEdit(id, currentText) {
    setEditingId(id);
    setEditingText(currentText);
}

function cancelEdit() {
    setEditingId(null);
    setEditingText("");
}

async function saveEdit(id) {
    const trimmed = editingText.trim();
    if (trimmed === "") return; // ignore empty updates
    try {
        const task = tasks.find(t => t.id === id);
        await axios.put(`${API_URL}/api/tasks/${id}`, { Name: trimmed, IsComplete: task.completed });
        setTasks(prev => prev.map(t => t.id === id ? { ...t, text: trimmed } : t));
    } catch (error) {
        console.error("Error saving task:", error);
    }
    cancelEdit();
}
async function TaskCompletion(id) {
    try {
        // Find task in current state (don't fetch from backend!)
        const task = tasks.find(t => t.id === id);
        if (!task) return;
        
        // Update backend
        await axios.put(`${API_URL}/api/tasks/${id}`, {
            Name: task.text,
            IsComplete: !task.completed  // Toggle completion
        });
        
        // Update local state
        setTasks(prev => prev.map(t => 
            t.id === id ? { ...t, completed: !t.completed } : t
        ));
    } catch (error) {
        console.error("Error toggling task:", error);
    }
}

return (
    <div className="to-do-list">
        <h1>My To-Do List</h1>
        <div>
            <input
                type="text"
                placeholder="Enter your task...."
                value={newTask}
                onChange={handleInputChange}
            />
            <button className="add-task-button" onClick={addTask}>Add Task</button>

        </div>

        <ol>
            {tasks.map((task) => (
                <li key={task.id}>
                    {editingId === task.id ? (
                        <>
                            <input
                                type="text"
                                value={editingText}
                                onChange={(e) => setEditingText(e.target.value)}
                            />

                            <button className="add-task-button" onClick={() => saveEdit(task.id)}>Save</button>
                            <button className="delete-button" onClick={cancelEdit}>Cancel</button>
                        </>
                    ) : (
                        <>
                            <input
                                type="checkbox"
                                checked={task.completed}
                                onChange={() => TaskCompletion(task.id)}
                            />
                            <span className={`text ${task.completed ? 'completed' : ''}`}>{task.text}</span>
                            <button className="add-task-button" onClick={() => startEdit(task.id, task.text)}>✏️</button>
                            <button className="delete-button" onClick={() => deleteTask(task.id)}>🗑️</button>
                        </>
                    )}
                </li>
            ))}
        </ol>
        <div className="footer">
            Total tasks: {tasks.length}
        </div>
    </div>
);
}


export default ToDoList;