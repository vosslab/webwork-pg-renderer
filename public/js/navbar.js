(() => {
  const defaultProblemSource = `DOCUMENT();

loadMacros('PGstandard.pl', 'PGML.pl', 'parserRadioButtons.pl', 'PGcourse.pl');

$radio1 = RadioButtons(
    [ [ 'Red', 'Blue', 'Green' ], 'None of these' ],
    'Blue',    # correct answer
);

BEGIN_PGML
My favorite color is

[_]{$radio1}
END_PGML

BEGIN_PGML_SOLUTION
The correct answer to the first is [$radio1->correct_ans].
END_PGML_SOLUTION

ENDDOCUMENT();`;

  const randomSeed = () => 1 + Math.floor(Math.random() * 999999);
  const diagnosticLimit = 320;

  function boundedDiagnostic(...values) {
    const text = values.flat(Infinity)
      .filter(value => value !== undefined && value !== null)
      .map(value => String(value).replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim())
      .find(Boolean);
    if (!text) return '';
    return text.length > diagnosticLimit ? `${text.slice(0, diagnosticLimit - 1)}...` : text;
  }

  function encodeSource(source) {
    const bytes = new TextEncoder().encode(source);
    if (typeof bytes.toBase64 === 'function') return bytes.toBase64();

    let binary = '';
    for (let index = 0; index < bytes.length; index += 1) {
      binary += String.fromCharCode(bytes[index]);
    }
    return btoa(binary);
  }

  async function responseError(response, action) {
    let detail = response.statusText;
    try {
      const body = await response.text();
      if (body) detail = boundedDiagnostic(body) || detail;
    } catch (_) {
      // The status text is a suitable accessible fallback.
    }
    return new Error(`${action}: ${detail || `HTTP ${response.status}`}`);
  }

  function initializeEditor() {
    const workspace = document.querySelector('.editor-workspace');
    if (!workspace) return;

    const sourcePath = document.getElementById('sourceFilePath');
    const seedInput = document.getElementById('problemSeed');
    const templateSelect = document.getElementById('template-select');
    const currentEditPath = document.getElementById('currentEditPath');
    const status = document.getElementById('render-status');
    const iframe = document.getElementById('rendered-problem');
    const editorContainer = document.querySelector('.code-mirror-editor');
    const actionControls = [
      document.getElementById('load-problem'),
      document.getElementById('save-problem'),
      document.getElementById('render-button'),
      document.getElementById('randomize-seed')
    ].filter(Boolean);
    let actionPending = false;

    if (!sourcePath || !seedInput || !templateSelect || !currentEditPath || !status || !iframe || !editorContainer) return;
    if (!window.PGCodeMirrorEditor) {
      status.textContent = 'The source editor could not be loaded.';
      status.dataset.state = 'error';
      return;
    }

    const cm = new PGCodeMirrorEditor.View(editorContainer, {
      source: defaultProblemSource,
      language: 'pg',
      theme: 'Cobalt'
    });

    function setStatus(message, state = 'info') {
      status.textContent = message;
      status.dataset.state = state;
    }

    async function runAction(pendingMessage, action) {
      if (actionPending) return;
      actionPending = true;
      for (const control of actionControls) control.setAttribute('aria-disabled', 'true');
      setStatus(pendingMessage);
      try {
        await action();
      } catch (error) {
        setStatus(error.message, 'error');
      } finally {
        actionPending = false;
        for (const control of actionControls) control.removeAttribute('aria-disabled');
      }
    }

    function ensureDefaults() {
      if (!seedInput.value.trim()) seedInput.value = randomSeed();
      if (!templateSelect.value) templateSelect.value = 'default';
    }

    function appendRenderOptions(formData) {
      for (const checkbox of document.querySelectorAll('.checkbox-input:checked')) {
        formData.append(checkbox.name, checkbox.value || '1');
      }
    }

    function appendSource(formData) {
      ensureDefaults();
      formData.set('sourceFilePath', sourcePath.value);
      formData.set('problemSeed', seedInput.value);
      formData.set('outputFormat', templateSelect.value);
      formData.set('problemSource', encodeSource(cm.source));
    }

    async function render(formData) {
      const response = await fetch('render-api', { method: 'POST', body: formData });
      if (!response.ok) throw await responseError(response, 'Could not render the problem');
      const data = await response.json();
      if (data.flags?.error_flag) {
        const diagnostic = boundedDiagnostic(
          data.errors,
          data.error,
          data.message,
          data.flags.error_message,
          data.flags.error,
          data.flags.comment,
          data.pg_warnings,
          data.warning_messages
        );
        throw new Error(diagnostic ? `The problem has translator errors: ${diagnostic}` : 'The problem has translator errors.');
      }
      if (!data.renderedHTML) throw new Error('The renderer returned no problem HTML.');

      iframe.srcdoc = data.renderedHTML;
      const warning = data.debug && data.debug.perl_warn;
      const warningText = boundedDiagnostic(warning);
      setStatus(warningText ? `Rendered with warning: ${warningText}` : 'Rendered successfully.', warningText ? 'warning' : 'success');
    }

    document.getElementById('randomize-seed')?.addEventListener('click', () => {
      if (actionPending) return;
      seedInput.value = randomSeed();
      setStatus('A new seed is ready to render.');
    });

    document.getElementById('save-problem')?.addEventListener('click', () => {
      void runAction('Saving problem source...', async () => {
        const writeFilePath = sourcePath.value;
        const formData = new FormData();
        formData.set('problemSource', encodeSource(cm.source));
        formData.set('writeFilePath', writeFilePath);
        const response = await fetch('render-api/can', { method: 'POST', body: formData });
        if (!response.ok) throw await responseError(response, 'Could not save the file');
        const data = await response.text();
        currentEditPath.textContent = writeFilePath || 'Unsaved editor contents';
        setStatus(data ? `Saved ${writeFilePath}.` : 'Saved problem source.', 'success');
      });
    });

    document.getElementById('load-problem')?.addEventListener('click', () => {
      void runAction('Loading problem source...', async () => {
        const requestedPath = sourcePath.value;
        const formData = new FormData();
        formData.set('sourceFilePath', requestedPath);
        const response = await fetch('render-api/tap', { method: 'POST', body: formData });
        if (!response.ok) throw await responseError(response, 'Could not load the file');
        cm.source = await response.text();
        currentEditPath.textContent = requestedPath || 'Unsaved editor contents';
        setStatus(`Loaded ${requestedPath || 'problem source'}.`, 'success');
      });
    });

    document.getElementById('render-button')?.addEventListener('click', () => {
      void runAction('Rendering problem...', async () => {
        const formData = new FormData();
        formData.set('showComments', '1');
        appendSource(formData);
        if (templateSelect.value === 'debug') formData.set('clientDebug', '1');
        appendRenderOptions(formData);
        formData.set('_format', 'json');
        await render(formData);
      });
    });

    iframe.addEventListener('load', () => {
      const problemForm = iframe.contentDocument?.getElementById('problemMainForm');
      if (!problemForm || problemForm.dataset.rendererBound) return;
      problemForm.dataset.rendererBound = 'true';
      problemForm.addEventListener('submit', event => {
        event.preventDefault();
        void runAction('Checking answer...', async () => {
          const formData = new FormData(problemForm);
          const submitter = event.submitter;
          if (submitter?.name) formData.set(submitter.name, submitter.value);
          formData.set('_format', 'json');
          formData.set('isInstructor', '1');
          formData.set('includeTags', '1');
          formData.set('showComments', '1');
          appendSource(formData);
          appendRenderOptions(formData);
          await render(formData);
        });
      });
    });

    ensureDefaults();
  }

  document.addEventListener('DOMContentLoaded', initializeEditor);
})();
