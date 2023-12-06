const state = {
    x: [0, 0, 0, 0, 0, 0, 0, 0, 0],
    o: [0, 0, 0, 0, 0, 0, 0, 0, 0]
};

const teams = ['x', 'o'];

// Assign listeners so that the buttons toggle the state
for (let i = 0; i <= 8; i++) {
    teams.forEach((t) => {
        const id = t + i;
        const elem = document.getElementById(id);
        elem.addEventListener('click', () => {
            state[t][i] = ((state[t][i] + 1) % 2);
            elem.setAttribute('selected', state[t][i]);
        });
    })
}

// Function for turning the state into instructions like 'ldi xone,0b00001001'
const reduceState = () => {
    let ret = document.createElement('p');
    teams.forEach((t) => {
        ret.append(`ldi ${t}0,0b${state[t].reduce((r, b, i) => {
            return i < 8 ? `${b}` + r : r;
        }, "")}`);
        ret.append(document.createElement('br'));
        ret.append(`ldi ${t}1,0b0000000${state[t][8]}`);
        ret.append(document.createElement('br'));
    })
    ret.append('rcall write');
    ret.append(document.createElement('br'));
    ret.append('rcall delay');
    return ret;
}

const save = () => {
    const seqParent = document.getElementById('sequence');
    const seq = reduceState();
    seqParent.appendChild(seq);
};

// clears the board but keeps the assembly
const clear = () => {
    teams.forEach((t) => {
        for (let i = 0; i <= 8; i++) {
            const id = t + i;
            const elem = document.getElementById(id);
            elem.setAttribute('selected', 0);
            state[t][i] = 0;
        }
    })
};

// copies the assembly to the clipboard
const copy = () => {
    const seqParent = document.getElementById('sequence');
    navigator.clipboard.writeText(seqParent.innerText + "\n\nret");
};

// Set the save button behavior
const saveBtn = document.getElementById('save');
saveBtn.addEventListener('click', save)
window.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') save();
})

// Set the clear button behavior
const clearBtn = document.getElementById('clear');
clearBtn.addEventListener('click', clear);
// set the copy button behavior
const copyBtn = document.getElementById('copy');
copyBtn.addEventListener('click', copy)