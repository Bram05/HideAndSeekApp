#include "Equations.h"
#include <tracy/Tracy.hpp>

std::vector<Double> SolveQuadratic(const Double& a, const Double& b, const Double& c)
{
    ZoneScoped;
    assert(!a.close(Double(0)));
    // Double disc = b * b - 4 * a * c;
    Double disc = sqr(b);
    disc -= 4 * a * c;
    if (disc.isZero()) { return { -b / (2 * a) }; }
    if (disc < 0) return {};
    // if (disc.close(Double(0))) { return { -b / (2 * a) }; }
    // if (disc < Double(0)) return {};
    Double s = sqrt(disc);
    Double n = 2 * a;
    return { (-b - s) / n, (-b + s) / n };
    // return { (-b - sqrt(disc)) / (2 * a), (-b + sqrt(disc)) / (2 * a) };
}
