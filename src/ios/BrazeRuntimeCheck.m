// This file exists to provide a compile time error if the project does not includes the Swift
// runtime.
//
// Since the Braze Swift SDK 11.0.0, the SDK provides support for Swift concurrency. In Objective-C
// only projects, this leads to a runtime crash when initializing the SDK.
//
// Adding a Swift file to the app target ensures that Xcode properly links the Swift runtime during
// compilation, allowing Braze to work as expected.
//
// This file (BrazeRuntimeCheck.m) is compiled with `-DBRZ_SWIFT_VERSION=$(SWIFT_VERSION)`:
// - Defines the BRZ_SWIFT_VERSION preprocessor macro.
// - Sets its value to Xcode's SWIFT_VERSION build setting.
//   - In an Objective-C only project, SWIFT_VERSION is empty.
// - When BRZ_SWIFT_VERSION is empty, we prevent compilation to force the integrator to include the
//   Swift runtime.

#define EMPTY(...) (true __VA_OPT__(&& false))
#if EMPTY(BRZ_SWIFT_VERSION)
#error Objective-C only project detected. Braze requires the Swift runtime to be available.
#error Add an empty Swift file to your application target to resolve these errors.
#endif
