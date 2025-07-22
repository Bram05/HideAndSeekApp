#include "maths.h"

#include <gmp.h>
#include <mpfr.h>
#include <stdio.h>

A calc()
{
    mpfr_t val, pi;
    mpfr_rnd_t rnd = MPFR_RNDN;
    printf("Minimum precision is %d, the maximum is %ld\n", MPFR_PREC_MIN, MPFR_PREC_MAX);
    mpfr_inits2(53, val, pi, NULL);
    mpfr_const_pi(pi, rnd);
    mpfr_set_ui(val, 1, rnd);
    mpfr_exp(val, val, rnd);
    mpfr_pow(val, val, pi, rnd);
    mpfr_log(val, val, rnd);
    mpfr_sin(val, val, rnd);
    mpfr_asin(val, val, rnd);
    double x = mpfr_get_d(val, rnd);
    A res;
    res.x = x;
    return res;
}
