#include "Equations.h"
#include <cassert>
#include <tracy/Tracy.hpp>

std::vector<Double> SolveQuadratic(const Double& a, const Double& b, const Double& c)
{
    ZoneScoped;
    assert(!a.close(Double(0)));
    Double disc = sqr(b);
    disc -= 4 * a * c;
    if (disc.isZero()) { return { -b / (2 * a) }; }
    if (disc < 0) return {};
    Double s = sqrt(disc);
    Double n = 2 * a;
    return { (-b - s) / n, (-b + s) / n };
}
