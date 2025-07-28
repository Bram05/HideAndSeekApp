#include "Constants.h"

namespace Constants
{
    static Precision instance = Precision("1e-30");
    Precision::Precision(const Double& val)
        : precision{ val }
    {
    }
    const Double& Precision::GetPrecision() { return instance.precision; }
    void Precision::SetPrecision(const Double& val) { instance.precision = val; }

} // namespace Constants
