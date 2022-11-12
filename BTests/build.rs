use std::process::Command;

fn main() {
    let current_dir = std::env::current_dir().unwrap();
    let proto_dir = current_dir.join("src");

    println!("Protodir is {:#?}", proto_dir);

    assert!(proto_dir.exists());

    protobuf_strict::write_protos(&proto_dir);

    let protos = proto_dir.join("protos");

    assert!(protos.exists());

    macro_rules! write {
        ($output: expr, $args: expr) => {
            let output_path = current_dir.join($output).join("Sources").join($output).join("protos");

            println!("Output path is {:#?}", output_path);

            let _ = std::fs::remove_dir_all(&output_path);

            std::fs::create_dir_all(&output_path).expect("Creating dirs failed");

            assert!(output_path.exists());

            for proto in &protobuf_strict::protos() {
                let status = Command::new("protoc")
                    .arg(format!("--proto_path={}", protos.to_str().unwrap()))
                    .arg(format!("--swift_out={}", output_path.to_str().unwrap()))
                    .arg("--swift_opt=Visibility=Public")
                    .arg(format!("{}.proto", proto))
                    .args(&$args)
                    .status()
                    .unwrap();

                assert!(status.success());
            }
        };
    }

    let empty: [&str; 0] = [];

    write!("generated", empty);

    println!("Generated the normal protos");

    let uuids: String = protobuf_strict::get_uuids().join("|");
    let args = [
        format!("--swift_opt=Uuids={}", uuids),
        "--swift_opt=RemoveBoilerplateCode=true".to_string()
    ];

    write!("bgenerated", args);
}