#pragma once
#include "Double.h"
namespace Constants
{
    const Double CircumferenceEarth = Double(40075017); // metres
    const Double radiusEarth        = Double(6371000);
    const Double epsilon            = Double(1e-10);
    inline Double pi(mpfr_prec_t precision = 150)
    {
        mpfr_t pi_val;
        mpfr_init2(pi_val, precision);
        mpfr_const_pi(pi_val, MPFR_RNDN);
        return Double(pi_val);
    }
} // namespace Constants
