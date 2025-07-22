#pragma once
#include <iostream>

#include <mpfr.h>
class Double
{
public:
    Double(double x);
    Double(int x);
    Double(mpfr_t p)
    {
        mpfr_init2(val, mpfr_get_prec(p));
        mpfr_set(val, p, MPFR_RNDN);
    }
    ~Double();
    Double(const Double& other);
    Double& operator=(const Double& other);

    double ToDouble() const;
    bool close(const Double& other) const;
    bool isZero() const { return close(Double(0)); }
    friend Double abs(const Double& p);
    friend Double sqrt(const Double& p);
    bool operator==(const Double& other) const { return close(other); }
    bool operator!=(const Double& other) const { return !(*this == other); }

    void operator+=(const Double& other);
    void operator-=(const Double& other);

    friend bool operator<(const Double& x, const Double& y);
    friend bool operator>(const Double& x, const Double& y);
    friend bool operator<=(const Double& x, const Double& y);
    friend bool operator>=(const Double& x, const Double& y);
    friend bool operator>(const Double& x, double y) { return x > Double(y); }
    friend Double operator-(const Double& x);
    friend Double operator+(const Double& x, const Double& y);
    friend Double operator-(const Double& x, const Double& y);
    friend Double operator*(const Double& x, const Double& y);
    friend Double operator/(const Double& x, const Double& y);
    friend Double sin(const Double& x);
    friend Double cos(const Double& x);
    friend Double tan(const Double& x);
    friend Double asin(const Double& x);
    friend Double acos(const Double& x);
    friend Double atan(const Double& x);
    friend Double atan2(const Double& y, const Double& x);
    friend std::ostream& operator<<(std::ostream& os, const Double& d);

private:
    mpfr_t val;
};
