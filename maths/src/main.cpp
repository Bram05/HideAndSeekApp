#include "Constants.h"
#include "Double.h"
#include "Expose.h"
#include "Shape.h"
#include "Tests.h"
#include "Vector3.h"
#include <chrono>
#include <iomanip>
#include <memory>
#include <tracy/Tracy.hpp>

int main()
{
    ZoneScoped;
    LatLng l = LatLng("-13", "90");
    std::cerr << l.ToVector3().ToLatLng() << '\n';
    // for (int i = 0; i < 200; i++)
    //     OneNonTransverseIntersection({ 10, 10 }, { -9.9, 190 }, { -10.1, 190 }, { 10, 10 },
    //                                  { 12, 12 }, { 10, 12 }, 1);
    // auto begin      = std::chrono::steady_clock::now();
    // mpfr_t val;
    // for (int i = 0; i < 100000; i++) mpfr_init2(val, 100);
    // auto end = std::chrono::steady_clock::now();
    // std::cout << "First part took \t" << (end - begin).count() / 1000 << " ms\n";
    //
    // begin = std::chrono::steady_clock::now();
    // // mpfr_t val;
    // mpfr_set_d(val, 10, MPFR_RNDN);
    // for (int i = 0; i < 100000; i++) mpfr_add(val, val, val, MPFR_RNDN);
    // end = std::chrono::steady_clock::now();
    // std::cout << "Second part took \t" << (end - begin).count() / 1000 << " ms\n";
    // // for (int i = 0; i < 10; i++) IntermediatePointsTest(1);
    // // print();
    // // OneNonTransverseIntersection({ 10, 10 }, { -9.9, 190 }, { -10.1, 190 }, { 10, 10 }, { 12,
    // 12
    // // },
    // //                              { 10, 12 }, 1);
    // auto totalend = std::chrono::steady_clock::now();
    // std::cout << "total time: \t" << (totalend - totalbegin).count() / 1000 << " ms\n";
}
