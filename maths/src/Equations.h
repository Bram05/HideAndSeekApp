#pragma once
#include "Double.h"
#include <cassert>
#include <vector>

// Solve ax^2+bx+c=0
std::vector<Double> SolveQuadratic(const Double& a, const Double& b, const Double& c);
