# Simple module to find USD.

if (WIN32)
    # On Windows we need to find ".lib"... which is CMAKE_STATIC_LIBRARY_SUFFIX
    # on WIN32 (CMAKE_SHARED_LIBRARY_SUFFIX is ".dll")
    set(USD_LIB_EXTENSION ${CMAKE_STATIC_LIBRARY_SUFFIX}
        CACHE STRING "Extension of USD libraries")
else ()
    # Defaults to ".so" on Linux, ".dylib" on MacOS
    set(USD_LIB_EXTENSION ${CMAKE_SHARED_LIBRARY_SUFFIX}
        CACHE STRING "Extension of USD libraries")
endif ()

if (WIN32)
    # Note: as of USD-0.19.11, the behavior on windows was that the .lib files
    # ALWAYS had no prefix, regardless of PXR_LIB_PREFIX.  However, the
    # PXR_LIB_PREFIX - which defaults to "lib", even on windows - IS used for
    # the .dll names.
    # So, if PXR_LIB_PREFIX is left at it's default value of "lib", you
    # have output libs like:
    #    usd.lib
    #    libusd.dll
    # The upshot is that, regardless of what PXR_LIB_PREFIX was set to when USD
    # was built, USD_LIB_PREFIX should nearly always be left at it's default ""
    # on windows
    set(USD_LIB_PREFIX ""
        CACHE STRING "Prefix of USD libraries")
else ()
    set(USD_LIB_PREFIX lib
        CACHE STRING "Prefix of USD libraries")
endif ()

find_path(USD_INCLUDE_DIR pxr/pxr.h
    PATHS ${USD_ROOT}/include
          $ENV{USD_ROOT}/include
    DOC "USD Include directory")

# We need to find either usd or usd_ms, with taking the prefix into account.

find_path(USD_LIBRARY_DIR
    NAMES
        ${USD_LIB_PREFIX}usd${USD_LIB_EXTENSION}
        # usd_msd is the monolithic-shared version of the library
        ${USD_LIB_PREFIX}usd_ms${USD_LIB_EXTENSION}
    PATHS ${USD_ROOT}/lib
          $ENV{USD_ROOT}/lib
    DOC "USD Libraries directory")

find_file(USD_GENSCHEMA
          names usdGenSchema
          HINTS
              ${USD_ROOT}
              $ENV{USD_ROOT}
          PATH_SUFFIXES
              bin
          DOC "USD Gen schema application")

if(USD_INCLUDE_DIR AND EXISTS "${USD_INCLUDE_DIR}/pxr/pxr.h")
    foreach(_usd_comp MAJOR MINOR PATCH)
        file(STRINGS
             "${USD_INCLUDE_DIR}/pxr/pxr.h"
             _usd_tmp
             REGEX "#define PXR_${_usd_comp}_VERSION .*$")
        string(REGEX MATCHALL "[0-9]+" USD_${_usd_comp}_VERSION ${_usd_tmp})
    endforeach()
    set(USD_VERSION ${USD_MAJOR_VERSION}.${USD_MINOR_VERSION}.${USD_PATCH_VERSION})
endif()

set(USD_LIBS ar;arch;cameraUtil;garch;gf;glf;hd;hdSt;hdx;hf;hgi;hgiGL;hio;js;kind;ndr;pcp;plug;pxOsd;sdf;sdr;tf;trace;usd;usdAppUtils;usdGeom;usdHydra;usdImaging;usdImagingGL;usdLux;usdRi;usdShade;usdShaders;usdSkel;usdSkelImaging;usdUI;usdUtils;usdviewq;usdVol;usdVolImaging;vt;work;usd_ms)

foreach (lib ${USD_LIBS})
    find_library(USD_${lib}_LIBRARY
        NAMES ${USD_LIB_PREFIX}${lib}${USD_LIB_EXTENSION}
        HINTS ${USD_LIBRARY_DIR})
    if (USD_${lib}_LIBRARY)
        add_library(${lib} INTERFACE IMPORTED)
        set_target_properties(${lib}
            PROPERTIES
            INTERFACE_LINK_LIBRARIES ${USD_${lib}_LIBRARY}
        )
        list(APPEND USD_LIBRARIES ${USD_${lib}_LIBRARY})
    endif ()
endforeach ()

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(USD
    REQUIRED_VARS
        USD_INCLUDE_DIR
        USD_LIBRARY_DIR
        USD_GENSCHEMA
        USD_LIBRARIES
    VERSION_VAR
        USD_VERSION)
