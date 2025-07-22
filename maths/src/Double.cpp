#include "Double.h"
#include "Constants.h"

mpfr_rnd_t rnd = MPFR_RNDN;
int precision  = 150;
Double::Double(double x)
{
    mpfr_init2(val, precision);
    mpfr_set_d(val, x, rnd);
}
Double::~Double() { mpfr_clear(val); }
Double::Double(int x)
{
    mpfr_init2(val, precision);
    mpfr_set_si(val, x, rnd);
}
Double::Double(const Double& other)
{
    mpfr_init2(val, mpfr_get_prec(other.val));
    mpfr_set(val, other.val, rnd);
}
Double& Double::operator=(const Double& other)
{
    if (this != &other)
    {
        mpfr_set_prec(val, mpfr_get_prec(other.val));
        mpfr_set(val, other.val, rnd);
    }
    return *this;
}

double Double::ToDouble() const { return mpfr_get_d(val, rnd); }
Double abs(const Double& p)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_abs(res, p.val, rnd);
    return Double(res);
}
Double sqrt(const Double& p)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_sqrt(res, p.val, rnd);
    return Double(res);
}

bool Double::close(const Double& other) const
{
    Double absv = abs(other - *this);
    return mpfr_cmp(absv.val, Constants::epsilon.val) < 0;
}
Double operator-(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_neg(res, x.val, rnd);
    return Double(res);
}
bool operator<(const Double& a, const Double& b) { return mpfr_cmp(a.val, b.val) < 0; }
bool operator>(const Double& x, const Double& y) { return mpfr_cmp(x.val, y.val) > 0; }
bool operator<=(const Double& x, const Double& y) { return mpfr_cmp(x.val, y.val) <= 0; }
bool operator>=(const Double& x, const Double& y) { return mpfr_cmp(x.val, y.val) >= 0; }
Double operator+(const Double& x, const Double& y)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_add(res, x.val, y.val, rnd);
    return Double(res);
}
void Double::operator+=(const Double& other) { mpfr_add(val, val, other.val, MPFR_RNDN); }
void Double::operator-=(const Double& other) { mpfr_sub(val, val, other.val, MPFR_RNDN); }
Double operator*(const Double& x, const Double& y)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_mul(res, x.val, y.val, rnd);
    return Double(res);
}
Double operator-(const Double& x, const Double& y)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_sub(res, x.val, y.val, rnd);
    return Double(res);
}
Double operator/(const Double& x, const Double& y)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_div(res, x.val, y.val, rnd);
    return Double(res);
}
Double sin(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_sin(res, x.val, rnd);
    return Double(res);
}
Double cos(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_cos(res, x.val, rnd);
    return Double(res);
}
Double tan(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_tan(res, x.val, rnd);
    return Double(res);
}
Double asin(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_asin(res, x.val, rnd);
    return Double(res);
}
Double acos(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_acos(res, x.val, rnd);
    return Double(res);
}
Double atan(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_atan(res, x.val, rnd);
    return Double(res);
}
Double atan2(const Double& y, const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, precision);
    mpfr_atan2(res, y.val, x.val, rnd);
    return Double(res);
}
std::ostream& operator<<(std::ostream& os, const Double& d)
{
    os << d.ToDouble();
    // Use this second version for high precision output
    // mpfr_exp_t exponent;
    // char* str = mpfr_get_str(0, &exponent, 10, 0, d.val, MPFR_RNDN);
    // os << str;
    // mpfr_free_str(str);
    return os;
}
