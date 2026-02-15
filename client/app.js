// Client-side JavaScript for Vibe Animation Competition

const API_BASE_URL = 'http://localhost:5000/api';

// Load participants on page load
document.addEventListener('DOMContentLoaded', function() {
    loadParticipants();

    // Handle registration form submission
    const registrationForm = document.getElementById('registrationForm');
    if (registrationForm) {
        registrationForm.addEventListener('submit', handleRegistration);
    }

    // Handle scoring form submission
    const scoringForm = document.getElementById('scoringForm');
    if (scoringForm) {
        scoringForm.addEventListener('submit', handleScoring);
        loadParticipantOptions();
    }
});

// Load and display participants
async function loadParticipants() {
    try {
        const response = await fetch(`${API_BASE_URL}/participants`);
        const participants = await response.json();

        displayParticipants(participants);
        displayLeaderboard(participants);
    } catch (error) {
        console.error('Error loading participants:', error);
    }
}

// Display participants list
function displayParticipants(participants) {
    const participantsList = document.getElementById('participantsList');
    if (!participantsList) return;

    participantsList.innerHTML = '';

    participants.forEach(participant => {
        const participantCard = document.createElement('div');
        participantCard.className = 'participant-card';
        participantCard.innerHTML = `
            <h3>${participant.name}</h3>
            <p><strong>Email:</strong> ${participant.email}</p>
            <p><strong>Animation:</strong> ${participant.animation_title}</p>
            <p><strong>Score:</strong> ${participant.score || 0}</p>
        `;
        participantsList.appendChild(participantCard);
    });
}

// Display leaderboard
function displayLeaderboard(participants) {
    const leaderboardList = document.getElementById('leaderboardList');
    if (!leaderboardList) return;

    // Sort by score descending
    const sortedParticipants = participants.sort((a, b) => (b.score || 0) - (a.score || 0));

    leaderboardList.innerHTML = '';

    sortedParticipants.forEach((participant, index) => {
        const leaderboardItem = document.createElement('div');
        leaderboardItem.className = 'leaderboard-item';
        leaderboardItem.innerHTML = `
            <h3>#${index + 1} ${participant.name}</h3>
            <p><strong>Animation:</strong> ${participant.animation_title}</p>
            <p><strong>Score:</strong> ${participant.score || 0}</p>
        `;
        leaderboardList.appendChild(leaderboardItem);
    });
}

// Handle registration form submission
async function handleRegistration(event) {
    event.preventDefault();

    const name = document.getElementById('name').value;
    const email = document.getElementById('email').value;
    const animationTitle = document.getElementById('animationTitle').value;

    try {
        const response = await fetch(`${API_BASE_URL}/participants`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                name: name,
                email: email,
                animation_title: animationTitle
            }),
        });

        if (response.ok) {
            alert('Registration successful!');
            document.getElementById('registrationForm').reset();
            loadParticipants();
        } else {
            alert('Registration failed. Please try again.');
        }
    } catch (error) {
        console.error('Error registering participant:', error);
        alert('An error occurred. Please try again.');
    }
}

// Load participant options for scoring form
async function loadParticipantOptions() {
    try {
        const response = await fetch(`${API_BASE_URL}/participants`);
        const participants = await response.json();

        const participantSelect = document.getElementById('participantSelect');
        participantSelect.innerHTML = '<option value="">Select Participant</option>';

        participants.forEach(participant => {
            const option = document.createElement('option');
            option.value = participant._id;
            option.textContent = `${participant.name} - ${participant.animation_title}`;
            participantSelect.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading participant options:', error);
    }
}

// Handle scoring form submission
async function handleScoring(event) {
    event.preventDefault();

    const participantId = document.getElementById('participantSelect').value;
    const score = parseFloat(document.getElementById('score').value);

    try {
        const response = await fetch(`${API_BASE_URL}/participants/${participantId}/score`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ score: score }),
        });

        if (response.ok) {
            alert('Score updated successfully!');
            document.getElementById('scoringForm').reset();
            loadParticipants();
            loadParticipantOptions();
        } else {
            alert('Failed to update score. Please try again.');
        }
    } catch (error) {
        console.error('Error updating score:', error);
        alert('An error occurred. Please try again.');
    }
}
