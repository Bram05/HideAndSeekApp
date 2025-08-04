#include "Constants.h"

mpfr_prec_t Constants::precision = 250;
static Constants* instance;
Constants::Constants() {}
const Double& Constants::GetEpsilon() { return instance->epsilon; }
void Constants::SetEpsilon(const Double& val) { instance->epsilon = val; }

void Constants::Init()
{
    instance                     = new Constants;
    instance->epsilon            = "1e-25";
    instance->circumferenceEarth = Double("40075017"); // metres
    instance->radiusEarth        = Double("6371000");
}

void Constants::Destroy() { delete instance; }
const Double& Constants::CircumferenceEarth() { return instance->circumferenceEarth; }
double Constants::CircumferenceEarthImprecise() { return 40075017; }
const Double& Constants::RadiusEarth() { return instance->radiusEarth; }

Double Constants::pi(mpfr_prec_t prec)
{
    {
        if (prec == -1) prec = instance->precision;
        mpfr_t pi_val;
        mpfr_init2(pi_val, instance->precision);
        mpfr_const_pi(pi_val, MPFR_RNDN);
        return Double(pi_val);
    }
}
