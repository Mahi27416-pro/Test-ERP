const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');

dotenv.config();
connectDB();

const app = express();

app.use(cors({ origin: 'http://localhost:3000', credentials: true }));
app.use(express.json());

// Routes
app.use('/api/auth',       require('./routes/auth'));
app.use('/api/students',   require('./routes/students'));
app.use('/api/faculty',    require('./routes/faculty'));
app.use('/api/attendance', require('./routes/attendance'));
app.use('/api/grades',     require('./routes/grades'));
app.use('/api/timetable',  require('./routes/timetable'));
app.use('/api/fees',       require('./routes/fees'));

app.get('/', (req, res) => res.json({ message: 'College ERP API running' }));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
