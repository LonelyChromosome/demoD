(() => {
  const REQUEST_EVENT = 'better-phenikaa-request-qldt';
  const RESULT_EVENT = 'better-phenikaa-qldt-result';
  const ERROR_EVENT = 'better-phenikaa-qldt-error';

  document.documentElement.dataset.betterPhenikaaBridge = 'ready';
  window.dispatchEvent(new CustomEvent('better-phenikaa-bridge-ready'));

  window.addEventListener(REQUEST_EVENT, async (event) => {
    let payload = {};
    try {
      payload = JSON.parse(String(event.detail || '{}'));
    } catch (_) {
      window.dispatchEvent(
        new CustomEvent(ERROR_EVENT, {
          detail: JSON.stringify({ message: 'Yêu cầu đồng bộ web không hợp lệ.' }),
        }),
      );
      return;
    }

    try {
      const response = await chrome.runtime.sendMessage({
        type: 'betterPhenikaaSyncQldt',
        start: payload.start,
        end: payload.end,
      });

      if (response && response.ok) {
        window.dispatchEvent(
          new CustomEvent(RESULT_EVENT, {
            detail: JSON.stringify(response),
          }),
        );
        return;
      }

      window.dispatchEvent(
        new CustomEvent(ERROR_EVENT, {
          detail: JSON.stringify({
            message:
              (response && response.message) ||
              'Không đọc được dữ liệu từ tab QLĐT.',
            code: response && response.code,
          }),
        }),
      );
    } catch (error) {
      window.dispatchEvent(
        new CustomEvent(ERROR_EVENT, {
          detail: JSON.stringify({
            message: `Web Bridge gặp lỗi: ${String(error)}`,
          }),
        }),
      );
    }
  });
})();
