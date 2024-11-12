// Register icons for use in mermaid diagrams.
component$.subscribe(function(a) {
    if (typeof mermaid !== 'undefined') {
        mermaid.registerIconPacks([
            {
                name: 'logos',
                loader: () =>
                    fetch('https://unpkg.com/@iconify-json/logos@1/icons.json').then((res) => res.json()),
            },
            {
                name: 'fab',
                loader: () =>
                    fetch('https://unpkg.com/@iconify-json/fa6-brands@1/icons.json').then((res) => res.json()),
            },
            {
                name: 'far',
                loader: () =>
                    fetch('https://unpkg.com/@iconify-json/fa6-regular@1/icons.json').then((res) => res.json()),
            },
            {
                name: 'fas',
                loader: () =>
                    fetch('https://unpkg.com/@iconify-json/fa6-solid@1/icons.json').then((res) => res.json()),
            },
        ]);
    }
})
