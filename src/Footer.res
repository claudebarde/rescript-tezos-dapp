@react.component
let make = () => {
    <footer
        style={ReactDOM.Style.make(~display="flex", ~justifyContent="center", ~alignItems="center", ())}
    >
        {"Made with ReScript and Taquito"->React.string}
    </footer>
}