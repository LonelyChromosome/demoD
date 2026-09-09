const QLDT_PATTERN = 'https://qldtbeta.phenikaa-uni.edu.vn/*';
const QLDT_HOME = 'https://qldtbeta.phenikaa-uni.edu.vn/';

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (!message || message.type !== 'betterPhenikaaSyncQldt') {
    return false;
  }

  syncFromAuthenticatedQldtTab(message.start, message.end)
    .then(sendResponse)
    .catch((error) => {
      sendResponse({
        ok: false,
        code: 'bridge_error',
        message: `Không thể đồng bộ QLĐT: ${String(error)}`,
      });
    });
  return true;
});

async function syncFromAuthenticatedQldtTab(start, end) {
  const tabs = await chrome.tabs.query({ url: QLDT_PATTERN });
  let tab = tabs.find((item) => item.id != null);

  if (!tab) {
    await chrome.tabs.create({ url: QLDT_HOME, active: true });
    return {
      ok: false,
      code: 'login_required',
      message:
        'Đã mở QLĐT. Hãy đăng nhập Microsoft trên tab chính thức, giữ tab đó mở rồi quay lại Better Phenikaa App và bấm Đồng bộ.',
    };
  }

  const [{ result } = {}] = await chrome.scripting.executeScript({
    target: { tabId: tab.id },
    world: 'MAIN',
    func: readQldtSchedule,
    args: [String(start || ''), String(end || '')],
  });

  if (!result || typeof result !== 'object') {
    return {
      ok: false,
      code: 'empty_result',
      message: 'Tab QLĐT không trả kết quả đồng bộ.',
    };
  }
  return result;
}

function readQldtSchedule(start, end) {
  return new Promise((resolve) => {
    try {
      if (
        !(
          window.edu &&
          edu.system &&
          edu.system.userId &&
          edu.system.iM != null &&
          typeof edu.system.makeRequest === 'function'
        )
      ) {
        resolve({
          ok: false,
          code: 'login_required',
          message:
            'Phiên QLĐT chưa sẵn sàng. Hãy hoàn tất đăng nhập Microsoft và chờ trang QLĐT tải xong.',
        });
        return;
      }

      const requestData = {
        action: 'SV_ThongTin_MH/DSA4BRINKCIpAiAPKSAv',
        func: 'pkg_congthongtin_hssv_thongtin.LayDSLichCaNhan',
        iM: edu.system.iM,
        strQLSV_NguoiHoc_Id: edu.system.userId,
        strNgayBatDau: start,
        strNgayKetThuc: end,
      };

      edu.system.makeRequest(
        {
          success(response) {
            let name = '';
            const preferred = document.querySelector('#lblHoTenNguoiDangNhap');
            if (preferred) {
              name = String(preferred.textContent || '').trim();
            }
            if (!name) {
              const spans = document.querySelectorAll('.nav-account button > span');
              for (const span of spans) {
                const candidate = String(span.textContent || '').trim();
                if (candidate) {
                  name = candidate;
                  break;
                }
              }
            }

            resolve({
              ok: true,
              envelope: JSON.stringify({ name, response }),
            });
          },
          error() {
            resolve({
              ok: false,
              code: 'qldt_request_failed',
              message:
                'QLĐT từ chối hoặc không trả dữ liệu lịch. Hãy tải lại tab QLĐT rồi thử lại.',
            });
          },
          type: 'POST',
          action: requestData.action,
          contentType: true,
          data: requestData,
          fakedb: [],
        },
        false,
        false,
        false,
        null,
      );
    } catch (error) {
      resolve({
        ok: false,
        code: 'page_script_error',
        message: `Không đọc được phiên QLĐT: ${String(error)}`,
      });
    }
  });
}
