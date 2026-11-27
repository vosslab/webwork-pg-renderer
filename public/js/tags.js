function setTagStatus(message, isError = false) {
    const status = document.getElementById('tag-status');
    status.textContent = message;
    status.dataset.state = isError ? 'error' : 'ready';
}

function addOptions(selectElement, optionsArray, selectedValue = '') {
    const options = [
        Object.assign(document.createElement('option'), { value: '', textContent: 'blank' }),
        ...optionsArray.map((value) => Object.assign(document.createElement('option'), { value, textContent: value }))
    ];
    selectElement.replaceChildren(...options);
    selectElement.value = selectedValue;
}

function updateDBsubject(selectedValue = '') {
    addOptions(document.getElementById('db-subject'), Object.keys(taxo || {}), selectedValue);
}

function updateDBchapter(selectedValue = '') {
    const subject = document.getElementById('db-subject').value;
    addOptions(document.getElementById('db-chapter'), Object.keys((taxo || {})[subject] || {}), selectedValue);
    updateDBsection();
}

function updateDBsection(selectedValue = '') {
    const subject = document.getElementById('db-subject').value;
    const chapter = document.getElementById('db-chapter').value;
    addOptions(document.getElementById('db-section'), ((taxo || {})[subject] || {})[chapter] || [], selectedValue);
}

function parseStringAndAppend(formData, elementName) {
    const field = document.getElementsByName(elementName)[0];
    const values = field.value.split(',').map((value) => value.trim()).filter(Boolean);
    formData.delete(elementName);
    values.forEach((value) => formData.append(elementName.toLowerCase(), value));
    return formData;
}

function submitTags(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const file = document.getElementById('tag-filename').value;
    if (!file) {
        setTagStatus('Load a problem before saving tags.', true);
        return;
    }
    let formData = new FormData(form);
    ['Description', 'Keywords', 'Resources'].forEach((name) => { formData = parseStringAndAppend(formData, name); });
    setTagStatus('Saving tags...');
    fetch(form.action, { body: formData, method: 'POST' })
        .then((response) => response.ok ? response.json() : Promise.reject(new Error(`Save failed: ${response.status}`)))
        .then((data) => {
            updateMetadata(data);
            setTagStatus(`Saved tags for ${file}.`);
            setLibraryStatus(`Saved tags for ${file}.`);
        })
        .catch((error) => {
            console.error(error);
            setTagStatus(error.message, true);
            setLibraryStatus(error.message, true);
        });
}

updateDBsubject();
document.getElementById('db-subject').addEventListener('change', updateDBchapter);
document.getElementById('db-chapter').addEventListener('change', updateDBsection);
document.getElementById('problem-tags').addEventListener('submit', submitTags);
