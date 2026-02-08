{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  fire,
  flask,
  flask-cors,
  gdown,
  gunicorn,
  mtcnn,
  numpy,
  opencv4,
  pandas,
  pgvector,
  pillow,
  psycopg,
  requests,
  retinaface,
  setuptools,
  tensorflow,
  tqdm,
}:

buildPythonPackage rec {
  pname = "deepface";
  version = "0.0.98";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "serengil";
    repo = "deepface";
    tag = "v${version}";
    hash = "sha256-Z9TDmNqeHXFeldXSl3Sz0SCR2UFW+sIA6aFPpSKY6bU=";
  };

  postPatch = ''
    # prevent collisions
    substituteInPlace setup.py \
      --replace-fail "data_files=[(\"\", [\"README.md\", \"requirements.txt\", \"package_info.json\"])]," "" \
      --replace-fail "install_requires=requirements," ""

    substituteInPlace deepface/DeepFace.py \
      --replace-fail "from lightphe import LightPHE" $'try:\n    from lightphe import LightPHE\nexcept Exception:\n    class LightPHE:\n        pass\n'
    substituteInPlace deepface/DeepFace.py \
      --replace-fail "from lightdsa import LightDSA" $'try:\n    from lightdsa import LightDSA\nexcept Exception:\n    class LightDSA:\n        pass\n'
    substituteInPlace deepface/modules/representation.py \
      --replace-fail "from lightphe import LightPHE" $'try:\n    from lightphe import LightPHE\nexcept Exception:\n    class LightPHE:\n        pass\n'
    substituteInPlace deepface/modules/recognition.py \
      --replace-fail "from lightdsa import LightDSA" $'try:\n    from lightdsa import LightDSA\nexcept Exception:\n    class LightDSA:\n        pass\n'
    substituteInPlace deepface/modules/encryption.py \
      --replace-fail "from lightphe import LightPHE" $'try:\n    from lightphe import LightPHE\n    from lightphe.models.Tensor import EncryptedTensor\nexcept Exception:\n    class LightPHE:\n        pass\n\n    class EncryptedTensor:\n        pass\n'
    substituteInPlace deepface/modules/encryption.py \
      --replace-fail "from lightphe.models.Tensor import EncryptedTensor" ""

    substituteInPlace deepface/models/face_detection/OpenCv.py \
      --replace-fail "opencv_path = self.__get_opencv_path()" "opencv_path = '/'.join(os.path.dirname(cv2.__file__).split(os.path.sep)[0:-4]) + \"/share/opencv4/haarcascades/\""
    substituteInPlace deepface/models/face_detection/OpenCv.py \
      --replace-fail "img, 1.1, 10, outputRejectLevels=True" "img, 1.05, 3, outputRejectLevels=True"
  '';

  build-system = [ setuptools ];

  dependencies = [
    fire
    flask
    flask-cors
    gdown
    gunicorn
    mtcnn
    numpy
    opencv4
    pandas
    pgvector
    pillow
    psycopg
    requests
    retinaface
    tensorflow
    tqdm
  ];

  # requires internet connection
  doCheck = false;

  pythonImportsCheck = [ "deepface" ];

  meta = {
    description = "Lightweight Face Recognition and Facial Attribute Analysis (Age, Gender, Emotion and Race) Library for Python";
    homepage = "https://github.com/serengil/deepface";
    changelog = "https://github.com/serengil/deepface/releases/tag/${src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ derdennisop ];
  };
}
