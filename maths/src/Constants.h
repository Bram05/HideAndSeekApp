#pragma once
#include "Double.h"
namespace Constants
{
    const mpfr_prec_t precision     = 150;
    const Double CircumferenceEarth = Double("40075017"); // metres
    const Double radiusEarth        = Double("6371000");
    // const Double epsilon            = Double("1e-30");
    inline Double pi(mpfr_prec_t prec = -1)
    {
        if (prec == -1) prec = precision;
        mpfr_t pi_val;
        mpfr_init2(pi_val, precision);
        mpfr_const_pi(pi_val, MPFR_RNDN);
        return Double(pi_val);
    }

    class Precision
    {
    public:
        Precision(const Double& val);
        static const Double& GetPrecision();
        static void SetPrecision(const Double& val);

    private:
        Double precision;
    };
} // namespace Constants
