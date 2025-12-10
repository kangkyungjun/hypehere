/**
 * Lottery Edit Page JavaScript
 * Handles fetching recent draws, displaying them in a table, and delete functionality
 */

// CSRF Token Helper
function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}

const csrftoken = getCookie('csrftoken');

// Wait for DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    console.log('[LotteryEdit] Initializing...');

    // DOM Elements
    const deleteBtn = document.getElementById('delete-selected-draws');
    const retryBtn = document.getElementById('retry-load-draws');

    // Content Elements
    const loadingState = document.getElementById('lottery-edit-loading');
    const errorState = document.getElementById('lottery-edit-error');
    const contentState = document.getElementById('lottery-edit-content');
    const drawsList = document.getElementById('lottery-draws-list');
    const duplicateWarning = document.getElementById('duplicate-warning');

    // State
    let selectedRounds = new Set();
    let drawsData = [];

    function showLoading() {
        loadingState.classList.remove('hidden');
        errorState.classList.add('hidden');
        contentState.classList.add('hidden');
    }

    function showError(message) {
        loadingState.classList.add('hidden');
        errorState.classList.remove('hidden');
        contentState.classList.add('hidden');
        errorState.querySelector('.error-message').textContent = message;
    }

    function hideError() {
        errorState.classList.add('hidden');
    }

    function showContent() {
        loadingState.classList.add('hidden');
        errorState.classList.add('hidden');
        contentState.classList.remove('hidden');
    }

    function setDeleteLoading(isLoading) {
        const btnText = deleteBtn.querySelector('.btn-text');
        const btnLoading = deleteBtn.querySelector('.btn-loading');

        deleteBtn.disabled = isLoading;

        if (isLoading) {
            btnText.classList.add('hidden');
            btnLoading.classList.remove('hidden');
        } else {
            btnText.classList.remove('hidden');
            btnLoading.classList.add('hidden');
        }
    }

    // API Functions
    async function loadRecentDraws() {
        console.log('[LotteryEdit] Loading recent draws...');
        showLoading();

        try {
            const response = await fetch('/admin-dashboard/api/admin/lottery/recent-draws/', {
                method: 'GET',
                credentials: 'same-origin',
                headers: {
                    'X-CSRFToken': csrftoken
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();

            if (data.success) {
                drawsData = data.draws;
                renderDraws(drawsData);
                showContent();
            } else {
                throw new Error(data.message || '회차 정보를 불러오는데 실패했습니다.');
            }

        } catch (error) {
            console.error('[LotteryEdit] Error loading draws:', error);
            showError(`회차 정보를 불러오는데 실패했습니다: ${error.message}`);
        }
    }

    async function deleteSelectedDraws() {
        if (selectedRounds.size === 0) {
            alert('삭제할 회차를 선택해주세요.');
            return;
        }

        const roundNumbers = Array.from(selectedRounds).sort((a, b) => b - a);
        const confirmMsg = `선택한 ${roundNumbers.length}개 회차를 삭제하시겠습니까?\n\n` +
                          `회차: ${roundNumbers.join(', ')}\n\n` +
                          `⚠️ 주의: 관련된 모든 조합 데이터도 함께 삭제됩니다.`;

        if (!confirm(confirmMsg)) {
            return;
        }

        console.log('[LotteryEdit] Deleting rounds:', roundNumbers);
        setDeleteLoading(true);

        let successCount = 0;
        let failCount = 0;
        const errors = [];

        for (const roundNumber of roundNumbers) {
            try {
                const response = await fetch(`/admin-dashboard/api/admin/lottery/draws/${roundNumber}/`, {
                    method: 'DELETE',
                    credentials: 'same-origin',
                    headers: {
                        'X-CSRFToken': csrftoken
                    }
                });

                const result = await response.json();

                if (response.ok && result.success) {
                    successCount++;
                    console.log(`[LotteryEdit] ✅ ${roundNumber}회차 삭제 완료`);
                } else {
                    failCount++;
                    const errorMsg = result.message || result.detail || '알 수 없는 오류';
                    errors.push(`${roundNumber}회차: ${errorMsg}`);
                    console.error(`[LotteryEdit] ❌ ${roundNumber}회차 삭제 실패:`, errorMsg);
                }

            } catch (error) {
                failCount++;
                errors.push(`${roundNumber}회차: ${error.message}`);
                console.error(`[LotteryEdit] ❌ ${roundNumber}회차 삭제 중 오류:`, error);
            }
        }

        setDeleteLoading(false);

        // 결과 메시지
        let resultMsg = `삭제 완료:\n✅ 성공: ${successCount}개`;
        if (failCount > 0) {
            resultMsg += `\n❌ 실패: ${failCount}개\n\n실패 상세:\n${errors.join('\n')}`;
        }

        alert(resultMsg);

        // 성공한 경우 로또 페이지로 돌아가기
        if (successCount > 0) {
            window.location.href = '/admin-dashboard/lottery/';
        } else {
            // 모두 실패한 경우 다시 로드
            loadRecentDraws();
        }
    }

    // Render Functions
    function renderDraws(draws) {
        drawsList.innerHTML = '';
        selectedRounds.clear();
        deleteBtn.disabled = true;

        let hasDuplicate = false;

        draws.forEach(draw => {
            const row = createDrawRow(draw);
            drawsList.appendChild(row);

            if (draw.is_duplicate) {
                hasDuplicate = true;
            }
        });

        // 중복 경고 표시
        if (hasDuplicate) {
            duplicateWarning.classList.remove('hidden');
        } else {
            duplicateWarning.classList.add('hidden');
        }
    }

    function createDrawRow(draw) {
        const row = document.createElement('tr');
        row.dataset.round = draw.round_number;

        if (draw.is_duplicate) {
            row.classList.add('duplicate-row');
        }

        // 체크박스 셀
        const checkCell = document.createElement('td');
        checkCell.className = 'col-select';
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.className = 'draw-checkbox';
        checkbox.dataset.round = draw.round_number;
        checkbox.addEventListener('change', handleCheckboxChange);
        checkCell.appendChild(checkbox);

        // 회차 번호 셀
        const roundCell = document.createElement('td');
        roundCell.className = 'col-round';
        roundCell.textContent = `${draw.round_number}회`;

        // 추첨일 셀
        const dateCell = document.createElement('td');
        dateCell.className = 'col-date';
        dateCell.textContent = draw.draw_date;

        // 당첨 번호 셀
        const numbersCell = document.createElement('td');
        numbersCell.className = 'col-numbers';
        const numberBalls = draw.numbers.map(num =>
            `<span class="number-ball ball-${getBallColor(num)}">${num}</span>`
        ).join(' ');
        numbersCell.innerHTML = numberBalls;

        // 보너스 번호 셀
        const bonusCell = document.createElement('td');
        bonusCell.className = 'col-bonus';
        bonusCell.innerHTML = `<span class="number-ball ball-${getBallColor(draw.bonus_number)}">${draw.bonus_number}</span>`;

        row.appendChild(checkCell);
        row.appendChild(roundCell);
        row.appendChild(dateCell);
        row.appendChild(numbersCell);
        row.appendChild(bonusCell);

        return row;
    }

    function getBallColor(num) {
        if (num <= 10) return 'yellow';
        if (num <= 20) return 'blue';
        if (num <= 30) return 'red';
        if (num <= 40) return 'gray';
        return 'green';
    }

    function handleCheckboxChange(event) {
        const roundNumber = parseInt(event.target.dataset.round);

        if (event.target.checked) {
            selectedRounds.add(roundNumber);
        } else {
            selectedRounds.delete(roundNumber);
        }

        // 삭제 버튼 활성화/비활성화
        deleteBtn.disabled = selectedRounds.size === 0;

        console.log('[LotteryEdit] Selected rounds:', Array.from(selectedRounds));
    }

    // Event Listeners
    if (deleteBtn) {
        deleteBtn.addEventListener('click', deleteSelectedDraws);
    }

    if (retryBtn) {
        retryBtn.addEventListener('click', loadRecentDraws);
    }

    // Auto-load draws when page loads
    loadRecentDraws();

    console.log('[LotteryEdit] Initialization complete');
});
