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
        ret.append(`ldi ${t}zero,0b${state[t].reduce((r, b, i) => {
            return i < 8 ? `${b}` + r : r;
        }, "")}`);
        ret.append(document.createElement('br'));
        ret.append(`ldi ${t}one,0b0000000${state[t][8]}`);
        ret.append(document.createElement('br'));
    })
    ret.append('rcall write');
    ret.append(document.createElement('br'));
    ret.append('rcall delay');
    return ret;
}

// Set the save button behavior
const saveBtn = document.getElementById('save');
saveBtn.addEventListener('click', () => {
    const seqParent = document.getElementById('sequence');
    const seq = reduceState();
    seqParent.appendChild(seq);
})