#include "Double.h"
#include "Constants.h"
#include <cstdio>
#include <cstdlib>
#include <mutex>
#include <stack>
#include <stdexcept>
#include <tracy/Tracy.hpp>
#include <vector>

constexpr int maxValuesAtStart = 1000;
std::vector<mpfr_t> variables;
std::stack<int> freeSpots;
std::mutex mutex;

void Double::Init()
{
    // Initializing mpfr_t is 'slow' so on startup we initialize a bunch and then reuse them
    variables = std::vector<mpfr_t>(maxValuesAtStart);
    for (int i = 0; i < maxValuesAtStart; i++)
    {
        freeSpots.push(i);
        mpfr_init2(variables[i], Constants::precision);
    }
    TracyMessageL("Initializing number of allocated mpfr_t");
}
void Double::InitVal()
{
    std::lock_guard<std::mutex> guard(mutex);
    if (freeSpots.empty())
    {
        int current = variables.size();
        std::vector<mpfr_t> newVariables(2 * current);
        for (int i = 0; i < current; i++) newVariables[i][0] = variables[i][0];
        variables = std::move(newVariables);
        TracyMessageL("Warning: increasing number of allocated mpfr_t");
        for (int i = current; i < 2 * current; i++)
        {
            mpfr_init2(variables[i], Constants::precision);
            freeSpots.push(i);
        }
    }
    val = freeSpots.top();
    freeSpots.pop();
}
void Double::Destroy()
{
    TracyMessageL("Destroying");
    for (mpfr_t& i : variables) { mpfr_clear(i); }
}

mpfr_rnd_t rnd = MPFR_RNDN;
Double::Double(double x)
{
    InitVal();
    mpfr_set_d(variables[val], x, rnd);
}
Double::Double() { InitVal(); }
Double::Double(const std::string& x)
{
    InitVal();
    mpfr_set_str(variables[val], x.c_str(), 10, rnd);
}
Double::Double(const char* x)
{
    InitVal();
    mpfr_set_str(variables[val], x, 10, rnd);
}
Double::Double(mpfr_t p)
{
    InitVal();
    mpfr_set(variables[val], p, MPFR_RNDN);
}
Double::~Double()
{
    std::lock_guard<std::mutex> guard(mutex);
    if (val != -1) freeSpots.push(val);
}
Double::Double(int x)
{
    InitVal();
    mpfr_set_si(variables[val], x, rnd);
}
Double::Double(const Double& other)
{
    InitVal();
    mpfr_set(variables[val], variables[other.val], rnd);
}
Double& Double::operator=(const Double& other)
{
    if (this != &other)
    {
        if (val == -1)
        {
            val = freeSpots.top();
            freeSpots.pop();
        }
        mpfr_set(variables[val], variables[other.val], rnd);
    }
    return *this;
}

double Double::ToDouble() const { return mpfr_get_d(variables[val], rnd); }
Double abs(const Double& p)
{
    Double d;
    mpfr_abs(variables[d.val], variables[p.val], rnd);
    return d;
}
Double sqrt(const Double& p)
{
    Double d;
    mpfr_sqrt(variables[d.val], variables[p.val], rnd);
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
    return mpfr_cmp(variables[absv.val], variables[Constants::GetEpsilon().val]) < 0;
}
Double operator-(const Double& x)
{
    Double d;
    mpfr_neg(variables[d.val], variables[x.val], rnd);
    return d;
}
bool operator<(const Double& a, const Double& b)
{
    return mpfr_cmp(variables[a.val], variables[b.val]) < 0;
}
bool operator>(const Double& x, const Double& y)
{
    return mpfr_cmp(variables[x.val], variables[y.val]) > 0;
}
bool operator<=(const Double& x, const Double& y)
{
    return mpfr_cmp(variables[x.val], variables[y.val]) <= 0;
}
bool operator>=(const Double& x, const Double& y)
{
    return mpfr_cmp(variables[x.val], variables[y.val]) >= 0;
}
Double operator+(const Double& x, const Double& y)
{
    Double d;
    mpfr_add(variables[d.val], variables[x.val], variables[y.val], rnd);
    return d;
}
void Double::operator+=(const Double& other)
{
    mpfr_add(variables[val], variables[val], variables[other.val], MPFR_RNDN);
}
void Double::operator-=(const Double& other)
{
    mpfr_sub(variables[val], variables[val], variables[other.val], MPFR_RNDN);
}
Double operator*(const Double& x, const Double& y)
{
    Double d;
    mpfr_mul(variables[d.val], variables[x.val], variables[y.val], rnd);
    return d;
}
Double operator-(const Double& x, const Double& y)
{
    Double d;
    mpfr_sub(variables[d.val], variables[x.val], variables[y.val], rnd);
    return d;
}
Double operator/(const Double& x, const Double& y)
{
    Double d;
    mpfr_div(variables[d.val], variables[x.val], variables[y.val], rnd);
    return d;
}
Double sin(const Double& x)
{
    ZoneScoped;
    Double d;
    mpfr_sin(variables[d.val], variables[x.val], rnd);
    return d;
}
Double cos(const Double& x)
{
    ZoneScoped;
    Double d;
    mpfr_cos(variables[d.val], variables[x.val], rnd);
    return d;
}
Double sinu(const Double& x)
{
    Double d;
    mpfr_sinu(variables[d.val], variables[x.val], 360, rnd);
    return d;
}
Double cosu(const Double& x)
{
    Double d;
    mpfr_cosu(variables[d.val], variables[x.val], 360, rnd);
    return d;
}
Double tanu(const Double& x)
{
    Double d;
    mpfr_tanu(variables[d.val], variables[x.val], 360, rnd);
    return d;
}
Double tan(const Double& x)
{
    Double d;
    mpfr_tan(variables[d.val], variables[x.val], rnd);
    return d;
}
Double asin(const Double& x)
{
    Double d;
    mpfr_asin(variables[d.val], variables[x.val], rnd);
    return d;
}
Double asinu(const Double& x)
{
    ZoneScoped;
    Double d;
    mpfr_asinu(variables[d.val], variables[x.val], 360, rnd);
    return d;
}
Double acos(const Double& x)
{
    ZoneScoped;
    Double d;
    mpfr_acos(variables[d.val], variables[x.val], rnd);
    return d;
}
Double atan(const Double& x)
{
    Double d;
    mpfr_atan(variables[d.val], variables[x.val], rnd);
    return d;
}
Double atan2(const Double& y, const Double& x)
{
    Double d;
    mpfr_atan2(variables[d.val], variables[y.val], variables[x.val], rnd);
    return d;
}
Double invSqrt(const Double& x)
{
    Double d;
    mpfr_rec_sqrt(variables[d.val], variables[x.val], rnd);
    return d;
}
Double sqr(const Double& x)
{
    Double d;
    mpfr_sqr(variables[d.val], variables[x.val], rnd);
    return d;
}
Double max(const Double& x, const Double& y)
{
    Double d;
    mpfr_max(variables[d.val], variables[x.val], variables[y.val], rnd);
    return d;
}
std::ostream& operator<<(std::ostream& os, const Double& d)
{
    os << d.ToString();
    return os;
}
std::string Double::ToString() const
{
    return std::to_string(mpfr_get_d(variables[val], rnd));
    // FILE* file = fopen("temp.txt", "w");
    // mpfr_out_str(file, 10, 0, variables[val], rnd);
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
