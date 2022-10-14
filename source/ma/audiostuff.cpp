#define STB_VORBIS_HEADER_ONLY
#include "extras/stb_vorbis.c"

#define MA_NO_OPUS
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
#include "extras/miniaudio_libopus.h"

#undef STB_VORBIS_HEADER_ONLY
#include "extras/stb_vorbis.c"

static ma_result ma_decoding_backend_init__libopus(void* pUserData, ma_read_proc onRead, ma_seek_proc onSeek, ma_tell_proc onTell, void* pReadSeekTellUserData, const ma_decoding_backend_config* pConfig, const ma_allocation_callbacks* pAllocationCallbacks, ma_data_source** ppBackend)
{
    ma_result result;
    ma_libopus* pOpus;

    (void)pUserData;

    pOpus = (ma_libopus*)ma_malloc(sizeof(*pOpus), pAllocationCallbacks);
    if (pOpus == NULL) {
        return MA_OUT_OF_MEMORY;
    }

    result = ma_libopus_init(onRead, onSeek, onTell, pReadSeekTellUserData, pConfig, pAllocationCallbacks, pOpus);
    if (result != MA_SUCCESS) {
        ma_free(pOpus, pAllocationCallbacks);
        return result;
    }

    *ppBackend = pOpus;

    return MA_SUCCESS;
}

static ma_result ma_decoding_backend_init_file__libopus(void* pUserData, const char* pFilePath, const ma_decoding_backend_config* pConfig, const ma_allocation_callbacks* pAllocationCallbacks, ma_data_source** ppBackend)
{
    ma_result result;
    ma_libopus* pOpus;

    (void)pUserData;

    pOpus = (ma_libopus*)ma_malloc(sizeof(*pOpus), pAllocationCallbacks);
    if (pOpus == NULL) {
        return MA_OUT_OF_MEMORY;
    }

    result = ma_libopus_init_file(pFilePath, pConfig, pAllocationCallbacks, pOpus);
    if (result != MA_SUCCESS) {
        ma_free(pOpus, pAllocationCallbacks);
        return result;
    }

    *ppBackend = pOpus;

    return MA_SUCCESS;
}

static void ma_decoding_backend_uninit__libopus(void* pUserData, ma_data_source* pBackend, const ma_allocation_callbacks* pAllocationCallbacks)
{
    ma_libopus* pOpus = (ma_libopus*)pBackend;

    (void)pUserData;

    ma_libopus_uninit(pOpus, pAllocationCallbacks);
    ma_free(pOpus, pAllocationCallbacks);
}

static ma_result ma_decoding_backend_get_channel_map__libopus(void* pUserData, ma_data_source* pBackend, ma_channel* pChannelMap, size_t channelMapCap)
{
    ma_libopus* pOpus = (ma_libopus*)pBackend;

    (void)pUserData;

    return ma_libopus_get_data_format(pOpus, NULL, NULL, NULL, pChannelMap, channelMapCap);
}

static ma_decoding_backend_vtable g_ma_decoding_backend_vtable_libopus =
{
    ma_decoding_backend_init__libopus,
    ma_decoding_backend_init_file__libopus,
    NULL, /* onInitFileW() */
    NULL, /* onInitMemory() */
    ma_decoding_backend_uninit__libopus
};

ma_resource_manager *init_resource()
{
    return (ma_resource_manager *)malloc(sizeof(ma_resource_manager));
}

void uninit_resource(ma_resource_manager *resourceManager)
{
    free(resourceManager);
}

ma_engine *init(ma_resource_manager *resourceManager)
{
    ma_result result;
    ma_resource_manager_config resourceManagerConfig;
    ma_engine_config engineConfig;
    ma_engine *engine = (ma_engine *)malloc(sizeof(ma_engine));

    ma_decoding_backend_vtable* pCustomBackendVTables[] =
    {
        &g_ma_decoding_backend_vtable_libopus
    };


    resourceManagerConfig = ma_resource_manager_config_init();
    resourceManagerConfig.ppCustomDecodingBackendVTables = pCustomBackendVTables;
    resourceManagerConfig.customDecodingBackendCount = sizeof(pCustomBackendVTables) / sizeof(pCustomBackendVTables[0]);
    resourceManagerConfig.pCustomDecodingBackendUserData = NULL;

    result = ma_resource_manager_init(&resourceManagerConfig, resourceManager);
    if (result != MA_SUCCESS) {
        printf("Failed to initialize resource manager.");
        return NULL;
    }

    engineConfig = ma_engine_config_init();
    engineConfig.pResourceManager = resourceManager;

    result = ma_engine_init(&engineConfig, engine);
    if (result != MA_SUCCESS) {
        printf("Failed to initialize engine.");
        return NULL;
    }

    return engine;
}

void uninit(ma_engine *engine)
{
    ma_engine_uninit(engine);
    free(engine);
}

ma_sound *loadSound(ma_engine *engine, const char *path, ma_sound_group *group = NULL)
{
    ma_result result;
    ma_sound *sound = (ma_sound *)malloc(sizeof(ma_sound));
    result = ma_sound_init_from_file(engine, path, MA_SOUND_FLAG_STREAM | MA_SOUND_FLAG_NO_SPATIALIZATION, group, NULL, sound);
    if (result != MA_SUCCESS)
    {
        return NULL; // Failed to load sound.
    }
    return sound;
}

void destroySound(ma_sound *sound)
{
    ma_sound_uninit(sound);
    free(sound);
}

int startSound(ma_sound *sound)
{
    ma_result result;
    result = ma_sound_start(sound);
    if (result != MA_SUCCESS)
    {
        return -1; // Failed to load sound.
    }
    return 0;
}

int stopSound(ma_sound *sound)
{
    ma_result result;
    result = ma_sound_stop(sound);
    if (result != MA_SUCCESS)
    {
        return -1; // Failed to load sound.
    }
    result = ma_sound_seek_to_pcm_frame(sound, 0);
    if (result != MA_SUCCESS)
    {
        return -2; // Failed to load sound.
    }
    return 0;
}

int pauseSound(ma_sound *sound)
{
    ma_result result;
    result = ma_sound_stop(sound);
    if (result != MA_SUCCESS)
    {
        return -1; // Failed to load sound.
    }
    return 0;
}

void setVolume(ma_sound *sound, float vol)
{
    ma_sound_set_volume(sound, vol);
}

float getVolume(ma_sound *sound)
{
    return ma_sound_get_volume(sound);
}

bool isPlaying(ma_sound *sound)
{
    return ma_sound_is_playing(sound);
}

bool isDone(ma_sound *sound)
{
    return ma_sound_at_end(sound);
}

void setPitch(ma_sound *sound, float pitch)
{
    ma_sound_set_pitch(sound, pitch);
}

float getPitch(ma_sound *sound)
{
    return ma_sound_get_pitch(sound);
}

float getTime(ma_sound *sound)
{
    float time = -1;
    ma_sound_get_cursor_in_seconds(sound, &time);
    return time;
}

float getLength(ma_sound *sound)
{
    float time = -1;
    ma_sound_get_length_in_seconds(sound, &time);
    return time;
}

void setTime(ma_sound *sound, float timeInSec)
{
    ma_result result;
    ma_uint64 lengthInPCMFrames;
    ma_uint32 sampleRate;

    if (sound == NULL)
    {
        return;
    }
    if (sound->pDataSource == NULL)
    {
        return;
    }

    float timePCM = 0;

    result = ma_data_source_get_data_format(sound->pDataSource, NULL, NULL, &sampleRate, NULL, 0);
    if (result != MA_SUCCESS)
    {
        return;
    }

    lengthInPCMFrames = timeInSec * sampleRate;

    ma_sound_seek_to_pcm_frame(sound, lengthInPCMFrames);
}

void setLooping(ma_sound *sound, bool shouldLoop)
{
    ma_sound_set_looping(sound, shouldLoop);
}

bool getLooping(ma_sound *sound)
{
    return ma_sound_is_looping(sound);
}

ma_sound_group* makeGroup(ma_engine* engine)
{
    ma_result result;
    ma_sound_group *group = (ma_sound_group *)malloc(sizeof(ma_sound_group));
    result =  ma_sound_group_init(engine, MA_SOUND_FLAG_NO_SPATIALIZATION, NULL, group);
    return group;
}

void killGroup(ma_sound_group* group)
{
    ma_sound_group_uninit(group);
    free(group);
}

int startGroup(ma_sound_group* group)
{
    ma_result result;
    result = ma_sound_group_start(group);
    if (result != MA_SUCCESS)
    {
        return -1; // Failed to load group.
    }
    return 0;
}

int haltGroup(ma_sound_group* group)
{
    ma_result result;
    result = ma_sound_group_stop(group);
    if (result != MA_SUCCESS)
    {
        return -1; // Failed to load sound.
    }
    return 0;
}
