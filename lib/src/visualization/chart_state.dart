// sp_core - visualization/chart_state.dart
//
// NOT YET IMPLEMENTED. Will hold platform-agnostic preparation of buffer/
// metrics data into chart-ready series (e.g. converting AccelSample lists
// and DominantFrequencyEstimator/IntensityEstimator output into plottable
// point lists), with NO Flutter widget dependencies.
//
// This is deliberately the ONLY visualization-related file that lives in
// sp_core itself. The actual chart rendering (fl_chart widgets or
// equivalent) lives in the separate sp_core_reference_app repo's
// lib/charts.dart - rendering/chart-library choice is exactly the kind of
// thing other teams building their own UI are expected to swap out, so it
// deliberately isn't part of this package.
