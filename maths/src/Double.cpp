#include "Double.h"
#include "Constants.h"
#include <cstdio>
#include <stdexcept>

mpfr_rnd_t rnd = MPFR_RNDN;
Double::Double(double x)
{
    mpfr_init2(val, Constants::precision);
    mpfr_set_d(val, x, rnd);
}
Double::Double(const std::string& x)
{
    mpfr_init2(val, Constants::precision);
    mpfr_set_str(val, x.c_str(), 10, rnd);
}
Double::Double(const char* x)
{
    mpfr_init2(val, Constants::precision);
    mpfr_set_str(val, x, 10, rnd);
}
Double::~Double() { mpfr_clear(val); }
Double::Double(int x)
{
    mpfr_init2(val, Constants::precision);
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
    mpfr_init2(res, Constants::precision);
    mpfr_abs(res, p.val, rnd);
    return Double(res);
}
Double sqrt(const Double& p)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_sqrt(res, p.val, rnd);
    return Double(res);
}

bool Double::close(const Double& other) const
{
    Double absv = abs(other - *this);
    return mpfr_cmp(absv.val, Constants::Precision::GetPrecision().val) < 0;
}
Double operator-(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
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
    mpfr_init2(res, Constants::precision);
    mpfr_add(res, x.val, y.val, rnd);
    return Double(res);
}
void Double::operator+=(const Double& other) { mpfr_add(val, val, other.val, MPFR_RNDN); }
void Double::operator-=(const Double& other) { mpfr_sub(val, val, other.val, MPFR_RNDN); }
Double operator*(const Double& x, const Double& y)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_mul(res, x.val, y.val, rnd);
    return Double(res);
}
Double operator-(const Double& x, const Double& y)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_sub(res, x.val, y.val, rnd);
    return Double(res);
}
Double operator/(const Double& x, const Double& y)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_div(res, x.val, y.val, rnd);
    return Double(res);
}
Double sin(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_sin(res, x.val, rnd);
    return Double(res);
}
Double cos(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_cos(res, x.val, rnd);
    return Double(res);
}
Double sinu(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_sinu(res, x.val, 360, rnd);
    return Double(res);
}
Double cosu(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_cosu(res, x.val, 360, rnd);
    return Double(res);
}
Double tanu(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_tanu(res, x.val, 360, rnd);
    return Double(res);
}
Double tan(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_tan(res, x.val, rnd);
    return Double(res);
}
Double asin(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_asin(res, x.val, rnd);
    return Double(res);
}
Double asinu(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_asinu(res, x.val, 360, rnd);
    return Double(res);
}
Double acos(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_acos(res, x.val, rnd);
    return Double(res);
}
Double atan(const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_atan(res, x.val, rnd);
    return Double(res);
}
Double atan2(const Double& y, const Double& x)
{
    mpfr_t res;
    mpfr_init2(res, Constants::precision);
    mpfr_atan2(res, y.val, x.val, rnd);
    return Double(res);
}
std::ostream& operator<<(std::ostream& os, const Double& d)
{
    os << d.ToString();
    return os;
}
std::string Double::ToString() const
{
    FILE* file = fopen("out.txt", "w");
    mpfr_out_str(file, 10, 0, val, rnd);
    char* buffer = new char[Constants::precision + 20];
    fclose(file);
    file    = fopen("out.txt", "r");
    char* p = fgets(buffer, Constants::precision + 20, file);
    if (p == nullptr) throw std::runtime_error("Unable to red from the file");
    std::string res = std::string(buffer);
    delete[] buffer;
    fclose(file);
    return res;
    // std::stringstream os;
    // FILE* file =
    // // os << ToDouble();
    // // Use this second version for high Constants::precision output
    // mpfr_exp_t exponent;
    // char* str     = mpfr_get_str(0, &exponent, 10, 0, val, MPFR_RNDN);
    // std::string s = str;
    // if (s.size() == 0) return os.str();
    // int off = (s[0] == '-' || s[0] == '+') ? 1 : 0;
    // s.insert(off + 1, 1, '.');
    // os << s << "*10^" << exponent;
    // mpfr_free_str(str);
    // return os.str();
}
