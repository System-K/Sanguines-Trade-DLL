cmake_minimum_required(VERSION 3.21)

project(SanguinesTrade
    VERSION 1.0.0
    DESCRIPTION "Sanguine's Trade -- Prisma UI bridge"
    LANGUAGES CXX
)

# -----------------------------------------------------------------------------
# Compiler settings
# -----------------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if (MSVC)
    add_compile_options(
        /W4         # warning level 4
        /WX-        # don't treat warnings as errors (CommonLib has some)
        /utf-8      # source files are UTF-8
        /Zc:__cplusplus
        /Zc:preprocessor
        /MP         # multiprocessor compilation
    )
endif()

# -----------------------------------------------------------------------------
# CommonLibSSE-NG -- pulled from vcpkg via the registry in vcpkg-configuration.json
# -----------------------------------------------------------------------------
find_package(CommonLibSSE CONFIG REQUIRED)

# -----------------------------------------------------------------------------
# Plugin target
# -----------------------------------------------------------------------------
add_commonlibsse_plugin(${PROJECT_NAME}
    SOURCES
        src/PCH.h
        src/Plugin.cpp
        src/PrismaUI_API.h
)

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_precompile_headers(${PROJECT_NAME} PRIVATE
    src/PCH.h
)

# -----------------------------------------------------------------------------
# Output naming -- ensure the DLL is "SanguinesTrade.dll" exactly
# -----------------------------------------------------------------------------
set_target_properties(${PROJECT_NAME} PROPERTIES
    OUTPUT_NAME "SanguinesTrade"
)

# -----------------------------------------------------------------------------
# Optional: copy the built DLL to a staging folder for easy install.
# Set DEPLOY_DIR to your Skyrim Data/SKSE/Plugins folder (or a Mod Organizer 2
# mod folder) to enable. Leave unset to skip.
# Example:
#   cmake -B build -S . -DDEPLOY_DIR="C:/Modding/MO2/mods/SanguinesTradeBridge/SKSE/Plugins"
# -----------------------------------------------------------------------------
if (DEFINED DEPLOY_DIR AND NOT "${DEPLOY_DIR}" STREQUAL "")
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${DEPLOY_DIR}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:${PROJECT_NAME}>" "${DEPLOY_DIR}/"
        COMMENT "Deploying $<TARGET_FILE_NAME:${PROJECT_NAME}> to ${DEPLOY_DIR}"
    )
endif()
