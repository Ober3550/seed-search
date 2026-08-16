// Node entry for the ore-count estimator. The logic + calibration tables live in
// public/estimate-core.js (shared verbatim with the browser / client-side seed
// page); the model is public/ore-model.json (served statically for the browser,
// required here for the server). See estimate-core.js for the model description.
const createEstimator = require("./public/estimate-core.js");
const MODEL = require("./public/ore-model.json"); // { B, KS, PMED, PLO }

module.exports = createEstimator(MODEL);
