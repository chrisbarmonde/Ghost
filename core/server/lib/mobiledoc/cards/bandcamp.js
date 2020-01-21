const createCard = require('../create-card');

module.exports = createCard({
    name: 'bandcamp',
    type: 'dom',
    config: {
        commentWrapper: true
    },
    render(opts) {
        if (!opts.payload.html) {
            return '';
        }

        let dom = opts.env.dom;

        // use the SimpleDOM document to create a raw HTML section.
        // avoids parsing/rendering of potentially broken or unsupported HTML
        const iframe = dom.createRawHTMLSection(opts.payload.html);

        let container = dom.createElement('div');
        container.setAttribute('class', 'kg-bandcamp-' + (opts.payload.position || 'center'));
        container.appendChild(iframe);

        return container;
    },

    absoluteToRelative(urlUtils, payload, options) {
        payload.html = payload.html && urlUtils.htmlAbsoluteToRelative(payload.html, options);
        return payload;
    },

    relativeToAbsolute(urlUtils, payload, options) {
        payload.html = payload.html && urlUtils.htmlRelativeToAbsolute(payload.html, options);
        return payload;
    }
});
