#include "Tests.h"
#include <iostream>

int main()
{
    Vector3Dart v{ 0, 1, 0 };
    int res = CircleTest(LatLngDart{ 0, 0 }, 100, &v, nullptr, 0, 1);
    std::cerr << "Result is " << res << '\n';
}
