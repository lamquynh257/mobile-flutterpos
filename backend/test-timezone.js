// Test timezone - Run this to debug
const testTimezone = () => {
    const now = new Date();
    console.log('=== TIMEZONE DEBUG ===');
    console.log('1. new Date():', now);
    console.log('2. toISOString():', now.toISOString());
    console.log('3. toLocaleString():', now.toLocaleString());
    console.log('4. Vietnam time:', now.toLocaleString('en-US', { timeZone: 'Asia/Ho_Chi_Minh' }));
    console.log('5. process.env.TZ:', process.env.TZ);
    console.log('6. Timezone offset (minutes):', now.getTimezoneOffset());

    // Test what we're actually saving
    const testDate = new Date('2025-12-13T23:12:00+07:00');
    console.log('\n=== TEST ISO STRING ===');
    console.log('Input: 2025-12-13T23:12:00+07:00');
    console.log('Parsed Date:', testDate);
    console.log('toISOString():', testDate.toISOString());
    console.log('Expected in DB: 2025-12-13 23:12:00');
};

testTimezone();
