#include "Equations.h"

std::vector<Double> SolveQuadratic(const Double& a, const Double& b, const Double& c)
{
    assert(!a.close(Double(0)));
    Double disc = b * b - 4 * a * c;
    if (disc.close(Double(0))) { return { -b / (2 * a) }; }
    if (disc < Double(0)) return {};
    return { (-b - sqrt(disc)) / (2 * a), (-b + sqrt(disc)) / (2 * a) };
}
