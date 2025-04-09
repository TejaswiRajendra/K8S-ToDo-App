const express = require('express');
const app = express();
const PORT = 3000;

let todos = [
    { id: 1, task: 'Learn Terraform' },
    { id: 2, task: 'Deploy Kubernetes' }
];

app.use(express.json());

app.get('/', (req, res) => {
    res.send('Welcome to Todo App on Kubernetes!');
});

app.get('/todos', (req, res) => {
    res.json(todos);
});

app.post('/todos', (req, res) => {
    const todo = {
        id: todos.length + 1,
        task: req.body.task
    };
    todos.push(todo);
    res.status(201).json(todo);
});

app.listen(PORT, () => {
    console.log(`Todo app running on http://localhost:${PORT}`);
});
