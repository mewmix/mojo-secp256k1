# secp256k1/fe.mojo
# This module provides field arithmetic for the secp256k1 prime field.
# It acts as a bridge to the pure-limb implementation in `field_limb.mojo`.

from .field_limb import (
    Fe as FeLimb,
    fe_zero as fe_zero_limb,
    fe_one as fe_one_limb,
    fe_clone as fe_clone_limb,
    fe_add as fe_add_limb,
    fe_sub as fe_sub_limb,
    fe_neg as fe_neg_limb,
    fe_mul as fe_mul_limb,
    fe_sqr as fe_sqr_limb,
    fe_inv as fe_inv_limb,
    fe_normalize_strong as fe_normalize_strong_limb,
    fe_from_bytes32 as fe_from_bytes32_limb,
    fe_to_bytes32 as fe_to_bytes32_limb,
)

# Re-export the main struct type.
alias Fe = FeLimb

# --- Constant Constructors ---

fn fe_zero() raises -> Fe:
    """Returns the field element representing zero."""
    return fe_zero_limb()

fn fe_one() raises -> Fe:
    """Returns the field element representing one."""
    return fe_one_limb()

# --- Core Operations ---

fn fe_copy(a: Fe) -> Fe:
    """Creates a copy of a field element."""
    return fe_clone_limb(a)

fn fe_add(a: Fe, b: Fe) raises -> Fe:
    """Adds two field elements."""
    return fe_add_limb(a, b)

fn fe_sub(a: Fe, b: Fe) raises -> Fe:
    """Subtracts one field element from another."""
    return fe_sub_limb(a, b)

fn fe_neg(a: Fe) raises -> Fe:
    """Negates a field element."""
    return fe_neg_limb(a)

fn fe_mul(a: Fe, b: Fe) raises -> Fe:
    """Multiplies two field elements."""
    return fe_mul_limb(a, b)

fn fe_sqr(a: Fe) raises -> Fe:
    """Squares a field element."""
    return fe_sqr_limb(a)

fn fe_inv(a: Fe) raises -> Fe:
    """Computes the modular multiplicative inverse of a field element."""
    return fe_inv_limb(a)

# --- Normalization ---

fn fe_normalize_strong(mut a: Fe) raises:
    """
    Normalizes a field element to its canonical representation.
    NOTE: In the limb-based backend, all operations maintain canonical form,
    so this function is a no-op. It exists for API compatibility with
    the previous DeciMojo-based implementation.
    """
    # The new implementation keeps Fe canonical, so this is a no-op.
    # The `mut a` is not modified.
    pass


# --- Byte Conversion ---

fn fe_from_bytes32(b: List[Int]) -> Fe:
    """Converts a 32-byte big-endian byte slice to a field element."""
    return fe_from_bytes32_limb(b)

fn fe_to_bytes32(a: Fe) -> List[Int]:
    """Converts a field element to a 32-byte big-endian byte slice."""
    return fe_to_bytes32_limb(a)
