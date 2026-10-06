import sys
import subprocess
import os

RUTA_BASE = os.path.dirname(os.path.abspath(__file__))
RUTA_REQ = os.path.join(RUTA_BASE, "requirements.txt")


def main():
    print("Instalando dependencias desde requirements.txt...")
    try:
        subprocess.run(
            [sys.executable, "-m", "pip", "install", "-r", RUTA_REQ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        
        import pymongo
        
        print(">> Instalación completada con éxito. Todas las dependencias están listas.")
    except Exception as e:
        print(f">> Error al instalar las dependencias: {e}")


if __name__ == "__main__":
    main()
