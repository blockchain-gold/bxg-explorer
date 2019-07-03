
require('babel-polyfill');

const config = require('../config');
const db = require('../lib/db');
const express = require('express');
const mongoose = require('mongoose');

const middleware = require('./lib/middleware');
const router = require('./lib/router');

mongoose.connect(db.getDSN(), db.getOptions());

const app = express();

middleware(app);
router(app);

app.listen(config.api.port, () => console.log(`BlocEx running on port ${config.api.port}`));

module.exports = app;
