#include "Constants.h"
#include "Expose.h"
#include "Shape.h"
#include "Tests.h"
#include "Vector3.h"
#include <memory>

int main()
{
    // IntermediatePointsTest(1);
    OneNonTransverseIntersection({ 10, 10 }, { -9.9, 190 }, { -10.1, 190 }, { 10, 10 }, { 12, 12 },
                                 { 10, 12 }, 1);
}
