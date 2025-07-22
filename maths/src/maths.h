#ifndef MAIN_H
#define MAIN_H

// todo: Test this actually for windows
#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

struct A
{
    double x;
};
extern "C"
{
    A calc();
}

#endif // MAIN_H
