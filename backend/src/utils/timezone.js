// Timezone utility for Vietnam (UTC+7)
// SIMPLIFIED VERSION - Just return current time, let MySQL timezone handle it

/**
 * Get current time - MySQL will handle timezone conversion
 * Since we set timezone in DATABASE_URL, just return new Date()
 * @returns {Date} Current date/time
 */
function getVietnamTime() {
    return new Date();
}

/**
 * Get current time as MySQL DATETIME string
 * @returns {string} MySQL DATETIME format: "YYYY-MM-DD HH:MM:SS"
 */
function getVietnamTimeString() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}

module.exports = {
    getVietnamTime,
    getVietnamTimeString
};
