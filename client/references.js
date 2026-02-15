// References and utility functions for the Vibe Animation Competition

// Animation scoring criteria weights
const SCORING_CRITERIA = {
    creativity: 0.3,
    technical_skill: 0.3,
    storytelling: 0.2,
    originality: 0.2
};

// Calculate score based on criteria
function calculateScore(criteriaScores) {
    let totalScore = 0;
    for (const [criterion, weight] of Object.entries(SCORING_CRITERIA)) {
        if (criteriaScores[criterion] !== undefined) {
            totalScore += criteriaScores[criterion] * weight;
        }
    }
    return Math.round(totalScore * 10) / 10; // Round to 1 decimal place
}

// Validate email format
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

// Format score for display
function formatScore(score) {
    return score.toFixed(1);
}

// Get current date in YYYY-MM-DD format
function getCurrentDate() {
    const now = new Date();
    return now.toISOString().split('T')[0];
}

// Debounce function for search inputs
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Export functions for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        calculateScore,
        validateEmail,
        formatScore,
        getCurrentDate,
        debounce
    };
}
