#include <stdint.h>
#include <limine.h>

__attribute__((used, section(".limine_requests")))
static volatile uint64_t limine_base_revision[3] =
    LIMINE_BASE_REVISION(3);

__attribute__((used, section(".limine_requests_start")))
static volatile uint64_t limine_requests_start[4] =
    LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".limine_requests")))
static volatile struct limine_framebuffer_request framebuffer_request = {
    .id = LIMINE_FRAMEBUFFER_REQUEST_ID,
    .revision = 0,
    .response = 0
};

__attribute__((used, section(".limine_requests_end")))
static volatile uint64_t limine_requests_end[2] =
    LIMINE_REQUESTS_END_MARKER;

void kernel_main(void)
{
    if (framebuffer_request.response == 0 ||
        framebuffer_request.response->framebuffer_count == 0) {
        for (;;) {
            __asm__ volatile ("hlt");
        }
    }

    struct limine_framebuffer *fb =
        framebuffer_request.response->framebuffers[0];

    volatile uint32_t *pixels = (volatile uint32_t *)fb->address;

    for (uint64_t y = 0; y < fb->height; y++) {
        for (uint64_t x = 0; x < fb->width; x++) {
            pixels[y * (fb->pitch / 4) + x] = 0x000000FF;
        }
    }

    for (;;) {
        __asm__ volatile ("hlt");
    }
}
