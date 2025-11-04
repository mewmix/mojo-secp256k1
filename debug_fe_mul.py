def main():
    a = 2
    b = 3
    c = (a * b) % 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
    print(c)

if __name__ == "__main__":
    main()
