#pragma once
#include <iostream>
#include <stdio.h>

#include <mpfr.h>

// A high precision double class,
// which uses mpfr to do all the calculations.
// It is usually more efficient to use += operators then + because of how mpfr works
class Double
{
public:
    Double();
    Double(double x);
    Double(int x);
    Double(const std::string& x);
    Double(const char* x);
    Double(mpfr_t p);
    Double(Double&& other);
    ~Double();
    Double(const Double& other);
    Double& operator=(const Double& other);

    static void Init();
    static void Destroy();

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

    // Angle in degrees
    friend Double sinu(const Double& x);
    friend Double cosu(const Double& x);
    friend Double tanu(const Double& x);
    friend Double asin(const Double& x);
    friend Double asinu(const Double& x);
    friend Double acos(const Double& x);
    friend Double atan(const Double& x);
    friend Double atan2(const Double& y, const Double& x);
    friend Double invSqrt(const Double& x);
    friend Double sqr(const Double& x);
    friend std::ostream& operator<<(std::ostream& os, const Double& d);
    friend Double max(const Double& x, const Double& y);
    std::string ToString() const;

private:
    void InitVal();
    __mpfr_struct* GetVal() const;
    int val;
};
