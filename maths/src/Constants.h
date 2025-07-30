#pragma once
#include "Double.h"
class Constants
{
public:
    Constants();
    static const Double& GetEpsilon();
    static void SetEpsilon(const Double& val);

    static void Init();
    static void Destroy();
    static const Double& CircumferenceEarth();
    static const Double& RadiusEarth();
    static Double pi(mpfr_prec_t prec = -1);

    static mpfr_prec_t precision;

private:
    Double epsilon;
    Double circumferenceEarth;
    Double radiusEarth;
};
