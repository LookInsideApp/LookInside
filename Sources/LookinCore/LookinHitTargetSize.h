#ifndef LookinHitTargetSize_h
#define LookinHitTargetSize_h

#include <math.h>

static const double LookinMinimumIPhoneTargetSize = 44.0;
static const double LookinMinimumMacTargetSize = 28.0;

/// Shared by Suggestions and target-app overlays. Zero means no size warning;
/// missing, invalid, or unsupported measurements are never reported as failures.
static inline double LookinHitTargetSizeDeficit(double width, double height, double minimum) {
    if (!isfinite(width) || !isfinite(height) || !isfinite(minimum) ||
        width <= 0 || height <= 0 || minimum <= 0 || width > 100000 || height > 100000) {
        return 0;
    }
    // Window conversion can turn 44 pt into 43.99999999999994 pt.
    if (width >= minimum - 0.000001 && height >= minimum - 0.000001) {
        return 0;
    }
    return 1.0 - fmin(width, height) / minimum;
}

#endif
