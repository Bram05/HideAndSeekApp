#include "Double.h"
#include "Constants.h"
#include <cstdio>
#include <cstdlib>
#include <mutex>
#include <stack>
#include <tracy/Tracy.hpp>
#include <vector>

constexpr int maxValuesAtStart = 1000;
std::vector<mpfr_t>* variables;
std::stack<int>* freeSpots;
std::mutex mutex;

void Double::Init()
{
    // Initializing mpfr_t is 'slow' so on startup we initialize a bunch and then reuse them
    // variables = new std::vector<mpfr_t>(maxValuesAtStart);
    std::cerr << "INIT\n";
    variables = new std::vector<mpfr_t>(maxValuesAtStart);
    freeSpots = new std::stack<int>();
    for (int i = 0; i < variables->size(); i++)
    {
        freeSpots->push(i);
        mpfr_init2((*variables)[i], Constants::precision);
    }
    TracyMessageL("Initializing number of allocated mpfr_t");
}
void Double::InitVal()
{
    std::lock_guard<std::mutex> guard(mutex);
    if (freeSpots->empty())
    {
        int current                       = variables->size();
        std::vector<mpfr_t>* newVariables = new std::vector<mpfr_t>(2 * current);
        for (int i = 0; i < current; i++) (*newVariables)[i][0] = (*variables)[i][0];
        variables = newVariables;
        std::cerr << "Warning: increasing number of allocated mpfr_t\n";
        for (int i = current; i < 2 * current; i++)
        {
            mpfr_init2((*variables)[i], Constants::precision);
            freeSpots->push(i);
        }
    }
    val = freeSpots->top();
    freeSpots->pop();
}
void Double::Destroy()
{
    ZoneScoped;
    std::cerr << "Destroying\n";
    for (int i = 0; i < variables->size(); i++) { mpfr_clear((*variables)[i]); }
    delete variables;
    delete freeSpots;
}
__mpfr_struct* Double::GetVal() const
{
    std::lock_guard<std::mutex> guard(mutex);
    return (*variables)[val];
}

mpfr_rnd_t rnd = MPFR_RNDN;
Double::Double(double x)
{
    InitVal();
    mpfr_set_d(GetVal(), x, rnd);
}
Double::Double() { InitVal(); }
Double::Double(const std::string& x)
{
    InitVal();
    mpfr_set_str(GetVal(), x.c_str(), 10, rnd);
}
Double::Double(const char* x)
{
    InitVal();
    mpfr_set_str(GetVal(), x, 10, rnd);
}
Double::Double(mpfr_t p)
{
    InitVal();
    mpfr_set(GetVal(), p, MPFR_RNDN);
}
Double::~Double()
{
    std::lock_guard<std::mutex> guard(mutex);
    if (val != -1) freeSpots->push(val);
}
Double::Double(int x)
{
    InitVal();
    mpfr_set_si(GetVal(), x, rnd);
}
Double::Double(const Double& other)
{
    InitVal();
    mpfr_set(GetVal(), other.GetVal(), rnd);
}
Double& Double::operator=(const Double& other)
{
    if (this != &other)
    {
        if (val == -1)
        {
            val = freeSpots->top();
            freeSpots->pop();
        }
        mpfr_set(GetVal(), other.GetVal(), rnd);
    }
    return *this;
}

double Double::ToDouble() const { return mpfr_get_d(GetVal(), rnd); }
Double abs(const Double& p)
{
    Double d;
    mpfr_abs(d.GetVal(), p.GetVal(), rnd);
    return d;
}
Double sqrt(const Double& p)
{
    Double d;
    mpfr_sqrt(d.GetVal(), p.GetVal(), rnd);
    return d;
}

Double::Double(Double&& other)
    : val{ other.val }
{
    other.val = -1;
}
bool Double::close(const Double& other) const
{
    Double absv = abs(other - *this);
    return mpfr_cmp(absv.GetVal(), Constants::GetEpsilon().GetVal()) < 0;
}
Double operator-(const Double& x)
{
    Double d;
    mpfr_neg(d.GetVal(), x.GetVal(), rnd);
    return d;
}
bool operator<(const Double& a, const Double& b) { return mpfr_cmp(a.GetVal(), b.GetVal()) < 0; }
bool operator>(const Double& x, const Double& y) { return mpfr_cmp(x.GetVal(), y.GetVal()) > 0; }
bool operator<=(const Double& x, const Double& y) { return mpfr_cmp(x.GetVal(), y.GetVal()) <= 0; }
bool operator>=(const Double& x, const Double& y) { return mpfr_cmp(x.GetVal(), y.GetVal()) >= 0; }
Double operator+(const Double& x, const Double& y)
{
    Double d;
    mpfr_add(d.GetVal(), x.GetVal(), y.GetVal(), rnd);
    return d;
}
void Double::operator+=(const Double& other)
{
    mpfr_add(GetVal(), GetVal(), other.GetVal(), MPFR_RNDN);
}
void Double::operator-=(const Double& other)
{
    mpfr_sub(GetVal(), GetVal(), other.GetVal(), MPFR_RNDN);
}
Double operator*(const Double& x, const Double& y)
{
    Double d;
    mpfr_mul(d.GetVal(), x.GetVal(), y.GetVal(), rnd);
    return d;
}
Double operator-(const Double& x, const Double& y)
{
    Double d;
    mpfr_sub(d.GetVal(), x.GetVal(), y.GetVal(), rnd);
    return d;
}
Double operator/(const Double& x, const Double& y)
{
    Double d;
    mpfr_div(d.GetVal(), x.GetVal(), y.GetVal(), rnd);
    return d;
}
Double sin(const Double& x)
{
    ZoneScoped;
    Double d;
    mpfr_sin(d.GetVal(), x.GetVal(), rnd);
    return d;
}
Double cos(const Double& x)
{
    ZoneScoped;
    Double d;
    mpfr_cos(d.GetVal(), x.GetVal(), rnd);
    return d;
}
Double sinu(const Double& x)
{
    Double d;
    mpfr_sinu(d.GetVal(), x.GetVal(), 360, rnd);
    return d;
}
Double cosu(const Double& x)
{
    Double d;
    mpfr_cosu(d.GetVal(), x.GetVal(), 360, rnd);
    return d;
}
Double tanu(const Double& x)
{
    Double d;
    mpfr_tanu(d.GetVal(), x.GetVal(), 360, rnd);
    return d;
}
Double tan(const Double& x)
{
    Double d;
    mpfr_tan(d.GetVal(), x.GetVal(), rnd);
    return d;
}
Double asin(const Double& x)
{
    Double d;
    mpfr_asin(d.GetVal(), x.GetVal(), rnd);
    return d;
}
Double asinu(const Double& x)
{
    ZoneScoped;
    Double d;
    mpfr_asinu(d.GetVal(), x.GetVal(), 360, rnd);
    return d;
}
Double acos(const Double& x)
{
    ZoneScoped;
    Double d;
    mpfr_acos(d.GetVal(), x.GetVal(), rnd);
    return d;
}
Double atan(const Double& x)
{
    Double d;
    mpfr_atan(d.GetVal(), x.GetVal(), rnd);
    return d;
}
Double atan2(const Double& y, const Double& x)
{
    Double d;
    mpfr_atan2(d.GetVal(), y.GetVal(), x.GetVal(), rnd);
    return d;
}
Double invSqrt(const Double& x)
{
    Double d;
    mpfr_rec_sqrt(d.GetVal(), x.GetVal(), rnd);
    return d;
}
Double sqr(const Double& x)
{
    Double d;
    mpfr_sqr(d.GetVal(), x.GetVal(), rnd);
    return d;
}
Double max(const Double& x, const Double& y)
{
    Double d;
    mpfr_max(d.GetVal(), x.GetVal(), y.GetVal(), rnd);
    return d;
}
std::ostream& operator<<(std::ostream& os, const Double& d)
{
    os << d.ToString();
    return os;
}
std::string Double::ToString() const
{
    return std::to_string(mpfr_get_d(GetVal(), rnd));
    // FILE* file = fopen("temp.txt", "w");
    // mpfr_out_str(file, 10, 0, GetVal(), rnd);
    // char* buffer = new char[Constants::precision + 20];
    // fclose(file);
    // file    = fopen("temp.txt", "r");
    // char* p = fgets(buffer, Constants::precision + 20, file);
    // if (p == nullptr) throw std::runtime_error("Unable to red from the file");
    // std::string res = std::string(buffer);
    // delete[] buffer;
    // fclose(file);
    // return res;
}
