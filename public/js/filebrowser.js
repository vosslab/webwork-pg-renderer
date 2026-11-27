const rootFolders = Object.fromEntries(Array.from(
    document.getElementById('file-list').options,
    (option) => [option.text, option.value]
));

function setLibraryStatus(message, isError = false) {
    const status = document.getElementById('opl-status');
    if (!status) return;
    status.textContent = message;
    status.dataset.state = isError ? 'error' : 'ready';
}

function requestUrl(path) {
    return new URL(path, document.baseURI).href;
}

function selectedOption(form) {
    const select = form.querySelector('select');
    return select && select.options[select.selectedIndex];
}

function updateBrowser(formId, updateBackNav) {
    const form = document.getElementById(formId);
    const option = selectedOption(form);
    if (!option) return;
    const value = option.value;
    if (value === '/') {
        resetBackNav();
        return;
    }
    const formData = new FormData();
    let target = form.action;
    let processData;

    if (value.endsWith('/')) {
        const folder = value.replace(/^\//, '');
        formData.set('maxDepth', '1');
        formData.set('basePath', folder);
        processData = (data) => {
            const children = Object.fromEntries(Object.entries(data).map(([name, path]) => {
                const suffix = path.endsWith('/') ? '/' : '';
                return [name, `${folder}${name}${suffix}`];
            }));
            updateFileList(children);
            updateBackNav(option.text);
            setLibraryStatus(`Showing ${option.text || 'root'} directory.`);
        };
    } else if (value.endsWith('.pg')) {
        target = requestUrl('render-api/');
        formData.set('sourceFilePath', value.replace(/^\//, ''));
        formData.set('problemSeed', '1234');
        formData.set('outputFormat', 'static');
        formData.set('_format', 'json');
        formData.set('isInstructor', '1');
        formData.set('forceScaffoldsOpen', '1');
        formData.set('includeTags', '1');
        formData.set('showComments', '1');
        processData = (data) => {
            updateIframe(data.renderedHTML);
            updateMetadata(data);
            setLibraryStatus(`Loaded ${value}.`);
        };
    } else {
        resetBackNav();
        return;
    }

    fetch(target, { body: formData, method: 'POST' })
        .then((response) => response.ok ? response.json() : Promise.reject(new Error(`Request failed: ${response.status}`)))
        .then(processData)
        .catch((error) => {
            console.error(error);
            setLibraryStatus(error.message, true);
        });
}

function updateFileList(data) {
    const select = document.getElementById('file-list');
    const options = Object.keys(data).map((key) => {
        const option = document.createElement('option');
        option.textContent = key;
        option.value = data[key];
        if (key.includes('.')) option.className = key.endsWith('.pg') ? 'pg-file' : 'other-file';
        return option;
    });
    select.replaceChildren(...options);
}

function diveIn(updatePath) {
    const select = document.getElementById('back-nav');
    const current = select.options[0];
    const option = document.createElement('option');
    option.textContent = `${current.text}${updatePath}/`;
    option.value = `${current.value}${updatePath}/`;
    select.prepend(option);
    select.selectedIndex = 0;
}

function backOut() {
    const select = document.getElementById('back-nav');
    while (select.selectedIndex !== 0) select.remove(0);
}

function resetBackNav() {
    updateFileList(rootFolders);
    const select = document.getElementById('back-nav');
    select.selectedIndex = select.options.length - 1;
    backOut();
    setLibraryStatus('Choose a folder or problem to begin.');
}

function updateRawMetadata(text) {
    document.getElementById('raw-metadata').textContent = (text || '').replace(/#/g, '');
}

function updateIframe(html) {
    document.getElementById('rendered-problem').srcdoc = html || '';
}

function mergeArrays(...arrays) {
    return [...new Set(arrays.flat().filter((value) => typeof value === 'string' && value))];
}

function updateEach(container, info) {
    container.querySelectorAll('[name]').forEach((field) => {
        const value = info[field.name];
        if (field.type === 'checkbox') field.checked = value === 1 || value === '1' || value === true;
        else field.value = value ?? '';
    });
}

function updateMetadata(data) {
    const tags = data.tags || {};
    tags.resources = mergeArrays(tags.resources || [], data.resources || [], data.pgResources || []);
    if (tags.isplaceholder === 1) {
        updateEach(document.getElementById('tag-wrapper'), { Resources: tags.resources.join(', ') });
        updateEach(document.getElementById('flags-wrapper'), {});
        document.getElementById('tag-filename').value = '';
        document.getElementById('save-tags').disabled = true;
        updateRawMetadata('');
        setLibraryStatus(`${tags.file} is a placeholder; tags cannot be saved.`, true);
        return;
    }
    document.getElementById('tag-filename').value = tags.file || '';
    updateRawMetadata(data.raw_metadata_text || '');
    tags.Description = (tags.description || []).join('\n');
    tags.Keywords = (tags.keywords || []).join(', ');
    tags.Resources = tags.resources.join(', ');
    updateEach(document.getElementById('tag-wrapper'), { ...tags, DBsubject: '', DBchapter: '', DBsection: '' });
    updateDBsubject(tags.DBsubject || '');
    updateDBchapter(tags.DBchapter || '');
    updateDBsection(tags.DBsection || '');
    updateEach(document.getElementById('flags-wrapper'), data.flags || {});
    document.getElementById('save-tags').disabled = !tags.file;
}

document.getElementById('BackNavigation').addEventListener('change', () => updateBrowser('BackNavigation', backOut));
document.getElementById('FileBrowserForm').addEventListener('submit', (event) => { event.preventDefault(); updateBrowser('FileBrowserForm', diveIn); });
document.getElementById('file-list').addEventListener('dblclick', () => updateBrowser('FileBrowserForm', diveIn));
